Xively <- {};    // this makes a 'namespace'

class Xively.Client {
    ApiKey = null;
    triggers = [];

	constructor(apiKey) {
		this.ApiKey = apiKey;
	}
	
	/*****************************************
	 * method: PUT
	 * IN:
	 *   feed: a XivelyFeed we are pushing to
	 *   ApiKey: Your Xively API Key
	 * OUT:
	 *   HttpResponse object from Xively
	 *   200 and no body is success
	 *****************************************/
	function Put(feed){
		local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
		local request = http.put(url, headers, feed.ToJson());

		return request.sendsync();
	}
    function PutLocation(location){
		local url = "https://api.xively.com/v2/feeds/" + location.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
		local request = http.put(url, headers, location.ToJson());

		return request.sendsync();
	}	
	/*****************************************
	 * method: GET
	 * IN:
	 *   feed: a XivelyFeed we fulling from
	 *   ApiKey: Your Xively API Key
	 * OUT:
	 *   An updated XivelyFeed object on success
	 *   null on failure
	 *****************************************/
	function Get(feed){
		local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "User-Agent" : "xively-Imp-Lib/1.0" };
		local request = http.get(url, headers);
		local response = request.sendsync();
		if(response.statuscode != 200) {
			server.log("error sending message: " + response.body);
			return null;
		}
	
		local channel = http.jsondecode(response.body);
		for (local i = 0; i < channel.datastreams.len(); i++)
		{
			for (local j = 0; j < feed.Channels.len(); j++)
			{
				if (channel.datastreams[i].id == feed.Channels[j].id)
				{
					feed.Channels[j].current_value = channel.datastreams[i].current_value;
					break;
				}
			}
		}
	
		return feed;
	}

}
    

class Xively.Feed{
    FeedID = null;
    Channels = null;
    
    constructor(feedID, channels)
    {
        this.FeedID = feedID;
        this.Channels = channels;
    }
    
    function GetFeedID() { return FeedID; }

    function ToJson()
    {
        local json = "{ \"datastreams\": [";
        for (local i = 0; i < this.Channels.len(); i++)
        {
            json += this.Channels[i].ToJson();
            if (i < this.Channels.len() - 1) json += ",";
        }
        json += "] }";
        return json;
    }
}
class Xively.Location {
    FeedID = null;
    disposition = null;
    name = null;
    exposure = null;
    domain = null;
    ele = null;
    lat = null;
    lon = null;
    
    constructor(feedID)
    {
        this.FeedID = feedID;
    }
    function GetFeedID() { return FeedID; }
    
    function Set(disposition, name, exposure, domain, ele, lat, lon) {
        this.disposition = disposition;
        this.name = name;
        this.exposure = exposure;
        this.domain = domain;
        this.ele = ele;
        this.lat = lat;
        this.lon = lon;
    }
    function ToJson() { 
        local json = http.jsonencode({ "location": {disposition = this.disposition, name = this.name,
        exposure = this.exposure, domain = this.domain, ele = this.ele, lat = this.lat, lon = this.lon}});
        //server.log(json);
        return json;
    }
}
class Xively.Channel {
    id = null;
    current_value = null;
    mytag = "";
    
    constructor(_id)
    {
        this.id = _id;
    }
    
    function Set(value, tag) { 
    	this.current_value = value;
        this.mytag = tag;
    }
    
    function Get() { 
    	return this.current_value; 
    }
    
    function ToJson() { 
    	local json = http.jsonencode({id = this.id, current_value = this.current_value, tags = this.mytag});
        //server.log(json);
        return json;
    }
}
APIKEY <- "Paste your XIVELY API Key here";
client <- Xively.Client(APIKEY);

function setLocation(ele, lat, lon) {
    server.log("sending to Xively");
    location <- Xively.Location("Your Xively Feed ID");
    location.Set("mobile", "your city", "outdoor", "physical", ele, lat, lon)
    client.PutLocation(location);
}

device.on ("bssid", function(data) {
   setLocation(0, data.lat, data.lon); 
});
