
-- Configuration to connect to the MQTT broker.
BROKER = "192.168.100.10"   -- Ip/hostname of MQTT broker
BRPORT = 1883             -- MQTT broker port
BRUSER = ""           -- If MQTT authenitcation is used then define the user
BRPWD  = ""            -- The above user password
CLIENTID = "ESP8266-" ..  node.chipid() -- The MQTT ID. Change to something you like
WATCHDOGTIMER = 30000 -- 30 seconds
--WATCHDOGTIMER = 7000 --for test only
led_green = 2 -- is OK,GPIO 4 (GPIO5 on layout ..which is wrong, GREEN LED connected
led_red = 1 -- is OK, GPIO5 pin next to RXD, RED LED connected
gpio.mode(led_green, gpio.OUTPUT)
gpio.mode(led_red, gpio.OUTPUT)

watchdog_id=5

-- MQTT topics to subscribe
topics = {"test","sensor/meterkast","sensor/garage"} -- Add/remove topics to the array

-- Control variables.
pub_sem = 0         -- MQTT Publish semaphore. Stops the publishing whne the previous hasn't ended
current_topic  = 1  -- variable for one currently being subscribed to
topicsub_delay = 100 -- microseconds between subscription attempts, worked for me (local network) down to 5...YMMV


print "*** Started mqtt.lua *** "
-- connect to the broker
print "Start MQTT Client"
-- m = mqtt.Client( CLIENTID, 30, BRUSER, BRPWD)
m = mqtt.Client(CLIENTID)

-- function to reconnected after a disconnect...but doesn't seem to work
--m:disconnect(BROKER , BRPORT, 0, function(conn)
--     print("Disconencted!!")
--     -- m = mqtt.Client(CLIENTID)
--end)

m:connect( BROKER , BRPORT, 0, function(conn)
     print("Connected to MQTT!")
     mqtt_sub() --run the subscription function
end)



function mqtt_sub()
     print"subscribing..."
     if table.getn(topics) < current_topic then
          -- if we have subscribed to all topics in the array, run the main prog
          run_main_prog()
     else
          --subscribe to the topic
          m:subscribe(topics[current_topic] , 0, function(conn)
               print("Subscribing topic: " .. topics[current_topic - 1] )
          end)
          current_topic = current_topic + 1  -- Goto next topic
          --set the timer to rerun the loop as long there is topics to subscribe
          tmr.alarm(5, topicsub_delay, 0, mqtt_sub )
     end
end

-- Sample publish functions:
function publish_data1()
   if pub_sem == 0 then  -- Is the semaphore set=
     pub_sem = 1  -- Nop. Let's block it
     ldr=adc.read(0)
     m:publish("ESP1",ldr,0,0, function(conn) 
        -- Callback function. We've sent the data
        print("Sending data1: " .. ldr)
        pub_sem = 0  -- Unblock the semaphore
     end)
   end  
end

function watchDogKick()
     print("WATCHDOG KICK, no MQTT messages received, disconnected?")
     --m = mqtt.Client(CLIENTID)
     -- final call for help
     m:publish("ESP1-help","HELP",0,0, function(conn) 
     print(node.heap())
     end)
     node.restart()
end

--main program to run after the subscriptions are done
function run_main_prog()
     print("Main program mqtt.lua")
     
     tmr.alarm(2, 5000, 1, publish_data1 ) -- start 5 sec timer to send LDR value from ADC port
     -- Callback to receive the subscribed topic messages. 
     m:on("message", function(conn, topic, data)
        gpio.write(led_green, gpio.HIGH)
        print(topic) 
        print(data)     
        gpio.write(led_green, gpio.LOW) 
        if data == "ON" then
           gpio.write(led_red, gpio.HIGH)
        elseif data == "OFF" then
           gpio.write(led_red, gpio.LOW)
        else
           print('no request for IO')
        end
        --(re)set timer
        tmr.alarm(watchdog_id, WATCHDOGTIMER, 0, watchDogKick)
       
        
     end )
end
