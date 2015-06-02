print("server.lua   started")
led_green = 2 -- is OK,GPIO 4 (GPIO5 on layout ..which is wrong, GREEN LED connected
led_red = 1 -- is OK, GPIO5 pin next to RXD, RED LED connected
gpio.mode(led_green, gpio.OUTPUT)
gpio.mode(led_red, gpio.OUTPUT)
srv=net.createServer(net.TCP)

srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end
        buf = buf.."<h1> ESP8266 Web Server</h1>";
        buf = buf.."<p> led_green GPIO 4 <a href=\"?pin=ON1\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF1\"><button>OFF</button></a></p>";
        buf = buf.."<p> led_red   GPIO 5 <a href=\"?pin=ON2\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF2\"><button>OFF</button></a></p>";
        local _on,_off = "",""
        if(_GET.pin == "ON1")then
              gpio.write(led_green, gpio.HIGH);
        elseif(_GET.pin == "OFF1")then
              gpio.write(led_green, gpio.LOW);
        elseif(_GET.pin == "ON2")then
              gpio.write(led_red, gpio.HIGH);
        elseif(_GET.pin == "OFF2")then
              gpio.write(led_red, gpio.LOW);
        end
        client:send(buf);
        client:close();
        collectgarbage();
    end)
end)
