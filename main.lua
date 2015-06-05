broker = "mqtt"-- IP or hostname of MQTT broker
mqttport = 1883-- MQTT port (default 1883)
userID = ""    -- username for authentication if required
userPWD  = ""  -- user password if needed for security
GPIO0 = 3      -- IO Index of GPIO0 
GPIO2 = 4      -- IO Index of GPIO2

clientID = ""

gpio.mode(GPIO0, gpio.OUTPUT)
gpio.write(GPIO0, gpio.HIGH)
gpio.mode(GPIO2, gpio.OUTPUT)
gpio.write(GPIO2, gpio.HIGH)


tmr.alarm(1,1000, 1, function() 
    if wifi.sta.status() < 5 then
        print("Waiting for IP address!") 
    else 
        print("IP address is "..wifi.sta.getip()) 
        tmr.stop(1) 
        -- your code goes here

		local i = 1
		local smac = ""
		for w in string.gmatch(wifi.sta.getmac(), "[^-]+") do
			if i > 4 then smac = smac..w end
  			i = i + 1
		end
		clientID = "ESP"..smac

		m = mqtt.Client(clientID, 120, userID, userPWD)

		m:on("message", function(conn, topic, data)
			print(topic .. ":" )
			if data ~= nil then
				print(data)
			end
			if topic == "/reset/"..clientID then
				node.restart()
			elseif topic == "/gpio/"..clientID.."/0" then
				if data == "0" then
					gpio.write(GPIO0, gpio.LOW)
				else
					gpio.write(GPIO0, gpio.HIGH)
				end
			elseif topic == "/gpio/"..clientID.."/2" then
				if data == "0" then
					gpio.write(GPIO2, gpio.LOW)
				else
					gpio.write(GPIO2, gpio.HIGH)
				end
			end
		end)

		m:connect( broker , mqttport, 0,
		function(conn)
    		print("Connected to MQTT:" .. broker .. ":" .. mqttport .." as " .. clientID )
			m:subscribe("/reset/"..clientID,0, 
			function(conn)
				print("reset subscribe success") 
				m:subscribe("/gpio/"..clientID.."/0",0, 
				function(conn)
					print("GPIO0 subscribe success") 
					m:subscribe("/gpio/"..clientID.."/2",0, 
					function(conn)
						print("GPIO2 subscribe success") 
					end)
            	end)
            end)
		end)

	-- initial timer
    end 
end)
