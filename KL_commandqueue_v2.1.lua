-- https://stackoverflow.com/questions/18843610/fast-implementation-of-queues-in-lua
-- implement a queue
local COM_ADMIN = 1
local List = {}
function List.new ()
  return {first = 0, last = -1}
end

function List.pushleft (list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end
  
function List.pushright (list, value)
    local last = list.last + 1
    list.last = last
    list[last] = value
end
  
  function List.popleft (list)
    local first = list.first
    if first > list.last then error("list is empty") end
    local value = list[first]
    list[first] = nil        -- to allow garbage collection
    list.first = first + 1
    return value
  end
  
  function List.popright (list)
    local last = list.last
    if list.first > last then error("list is empty") end
    local value = list[last]
    list[last] = nil         -- to allow garbage collection
    list.last = last - 1
    return value
  end

  function List.size (list)
	return list.last - list.first + 1
  end

-------
local LinkedList = {}
function LinkedList.new(value)
    return {value=value,next=nil}
end

function LinkedList.append(node,value)
    if node == nil then
        return LinkedList.new(value)
    end

    local cur = node
    while (cur.next != nil) do
        cur = cur.next
    end

    cur.next = LinkedList.new(value)
    return node
end


local ManagedList = {}

function ManagedList.new()
    return {head=nil}
end

function ManagedList.pushleft(ml,value)
    local new_node = LinkedList.new(value)
    new_node.next = ml.head
    return {head=new_node}
end

function ManagedList.pushright(ml,value)
    if ml.head == nil then
        ml.head = LinkedList.new(value)
    else
        LinkedList.append(ml.head,value)
    end
    return ml
end

function ManagedList.insertAt(user,ml,index,value)
    if index < 0 then
        CONS_Printf(user,"index must be larger than -1. ("..index.." was given)")
        return ml
    end

    local prev = nil
    local cur_node = ml.head
    local cur_idx = 0

    while cur_node != nil and cur_idx < index do
        prev = cur_node
        cur_node = cur_node.next
        cur_idx = $ + 1
    end

    local new_node = LinkedList.new(value)
    new_node.next = cur_node
    if prev != nil then
        prev.next = new_node
    end
    if cur_idx != index then
        CONS_Printf(user,"index "..index.." is out of bounds. Item was put at end.")
    end

    if ml.head == nil or index == 0 then
        ml.head = new_node
    end

    return ml
end

function ManagedList.removeAt(user,ml,index)
    if index < 0 then
        CONS_Printf(user,"index must be larger than -1. ("..index.." was given)")
        return ml
    end

    local prev = nil
    local cur_node = ml.head
    local cur_idx = 0

    while cur_node != nil and cur_idx < index do
        prev = cur_node
        cur_node = cur_node.next
        cur_idx = $ +1
    end

    if cur_node == nil then
        CONS_Printf(user,"nothing to delete at index "..index)
        return ml
    end

    if prev != nil then
        -- target is beyond first node
        prev.next = cur_node.next
    else
        --target is first node - reassign head
        ml.head = cur_node.next
    end

    return ml
end

function ManagedList.popleft(user,ml)
    local result = ml.head
    ml = ManagedList.removeAt(user,ml,0)
    return result
end 

function ManagedList.clear(user,ml)
    while ml.head != nil do
        ml = ManagedList.removeAt(user,ml,0)
    end
    return ml
end

function ManagedList.editAt(user,ml,index,new_value)
    local cur_node = ml.head
    local cur_idx = 0

    while cur_node != nil and cur_idx < index do
        cur_node = cur_node.next
        cur_idx = $ + 1
    end

    if cur_node == nil then
        CONS_Printf(user,"Index "..index.." out of range")
        return
    end

    cur_node.value = new_value
    CONS_Printf(user,"Changed command at index "..index.." to '"..new_value.."'")
end

function ManagedList.noop(user)
    CONS_Printf(user,"If this server is not CG's SubBox you are using an illegitimate copy of commandQueue. Contact cglitcher#1172")
end

function ManagedList.showList(user,ml)
    local cur_node = ml.head
    local is_empty = true
    local idx = 0
    while cur_node != nil do
        local output = "{"..idx.."}: " .. cur_node.value
        CONS_Printf(user,output)
        cur_node = cur_node.next
        is_empty = false
        idx = $ + 1
    end
    if is_empty then
        CONS_Printf(user,"<empty list>")
    end
end

function ManagedList.getAllItems(ml)
    local cur_node = ml.head
    local is_empty = true
    local values = {}
    while cur_node != nil do
        table.insert(values,cur_node.value)
        cur_node = cur_node.next
        is_empty = false
    end
    return values
end

function ManagedList.isEmpty(ml)
    return ml.head == nil
end

---------
-- https://stackoverflow.com/questions/2282444/how-to-check-if-a-table-contains-an-element-in-lua
local Set = {}
function Set.new()
    return {}
end

function  Set.add(set, key)
    set[key] = true
end

function Set.remove(set, key)
    set[key] = nil
end

function Set.contains(set, key)
    return set[key] ~= nil
end

---------
-- https://stackoverflow.com/questions/1426954/split-string-in-lua
local function strsplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

---------
--------
-- Snatched from NuVote, which uses components written from Dr Nope and freeman
local function build_map_title(map)
	-- G_BuildMapTitle not available for 2.1
	local mapstr =  map.lvlttl.." "..(map.subttl and map.subtt1 or "")..(map.zonttl and map.zonttl or "")..(map.actnum and (" "..map.actnum) or "")
	mapstr = string.match(mapstr, "(.-)%s*$") -- remove trailing whitespaces
	return mapstr
end


local function query_map(query_arr)
	-- much of this yoinked from freeman and Dr_Nope maplist listmap utility
	-- build a list of every map
	-- filter out maps that DON"T have each word in provided query_arr
	local max= (36*26+26)+100
	local maptable = {}
	-- we loop thru again in case maps were loaded after this lua is
    for i=0,max do
        local map= mapheaderinfo[i]
        if map and map.lvlttl then
			table.insert(maptable,
						{id=i,
						extid = G_BuildMapName(i),
						name=build_map_title(map),
						sprint=map.levelflags&LF_SECTIONRACE,
						gametype=map.typeoflevel,
						hell=map.menuflags & LF2_HIDEINMENU,
						}
					)
        end
    end

	local direct_query = ""
	if #query_arr == 1 then
		if #query_arr[1] == 2 then
			direct_query = "map"..query_arr[1]
		end

		if #query_arr[1] == 5 and string.lower(string.sub(query_arr[1],1,3)) == "map" then
			direct_query = query_arr[1]
		end
	end
	if #direct_query > 0 then
		-- querying by mapid. I am allowing a lotta inefficiency.. but max ct is 1035 so whatevs
		for i=#maptable,1,-1
			if not string.find(string.lower(maptable[i].extid),string.lower(direct_query)) then table.remove(maptable, i) end
		end
	else
		-- querying with a string
		for i=1,#query_arr
			local testarg = string.lower(query_arr[i])
			for i=#maptable,1,-1
				if not string.find(string.lower(maptable[i].name),testarg) then table.remove(maptable, i) end
			end
		end
	end

	return maptable
end


local function one_match_or_print(p,query)
	local matches = query_map(query)

	if #matches > 1 then
		CONS_Printf(p,"Found multiple matches from your query. Try mapid?")
		CONS_Printf(p,"\130MAPID\128 | \130NAME")
		for i, match in ipairs(matches) do
			CONS_Printf(p,match.extid.." | "..match.name)
		end
		return nil
	elseif #matches == 0 then
		CONS_Printf(p,"Uh.. no maps matched your query, in both name and mapid. Check your spelling.")
		return nil
	end

	return matches[1]
end
----------
-----------
local enabled = CV_RegisterVar({
	name = "cq_commandqueue",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local popOnVote = CV_RegisterVar({
	name = "cq_poponvote",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local allow_suggestq = CV_RegisterVar({
	name = "cq_allowsuggestq",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local function ensureArg(user,arg,name,idx,mustBeNumber)
    if arg == nil then
        CONS_Printf(user,"Missing argument: "..name.." (argument #"..idx..")")
        return false
    end
    if mustBeNumber and tonumber(arg) == nil then
        local output = "Invalid number for argument"..name.." (argument #"..idx..") Must be an integer"
        CONS_Printf(user,output)
        return false
    end

    return true

end

local function showHelp(user,command)
    local help_help = {}
    help_help[1] = "\135commandqueue by cglitcher. Queue console commands to be executed at the end of intermission one at a time. 'helpq cq_command' to show help. List of cq_commands:"
    help_help[2] = "\131addq  popq  showq addfrontq"
    help_help[3] = "\131 editq deleteq suggestq"
    help_help[4] = "\131helpq why   insertq "
    help_help[5] = "\131cq_commandqueue cq_poponvote cq_whitelist"
    local help = {cq_commandqueue="\131cq_commandqueue \1331|0 \128- enable|disable command queue. (Disabled by default)"
        ,cq_poponvote="\131cq_poponvote \1331|0 - \128enable|disable popping the queue at the end of intermission. (Disabled by default)"
        ,cq_whitelist="\131cq_whitelist \133yourcommand - \128whitelist yourcommand for queuing. All commands must be whitelisted before they can be queued"
        ,addq=  "\131addq \133yourcommand \128- Add yourcommand to the queue. The queue will execute this in FIFO fashion"
        ,popq=  "\131popq \128- Executes the next command in the queue. This is done automatically after intermission when \129cq_poponvote\128 is enabled"
        ,showq= "\131showq \128- Displays all commands in the queue. Along with their indicies (zero indexed)"
        ,addfrontq="\131addfrontq \133yourcommand \128- Adds a command to the front of the queue. Will execute next on popq"
        ,editq= "\131editq \133index yourcommand\128 - changes the command at the specified index to your new command. showq to view 'indexes'"
        ,deleteq="\131deleteq \133index\128 - Deletes the command at the specified index. showq to view 'indexes'"
        ,insertq="\131insertq \133index yourcommand\128 - Inserts a command before the commdand at the specified index. showq to view 'indexes'"
        ,clearq="\131clearq \128 - Clears the entire queue. DANGER! Queue is not recoverable after this operation"
        ,suggestq="\131suggestq \133QUERY \128 Suggest a map to play next! Just type the name of the map you want to play, and a vote will be called to add it to the queue."
        ,helpq= "\131helpq \133cq_command \128 Shows help for the specified command queue command"
        ,why="Not a real command. Why does this mod exist? The intention is to give admins the ability to queue up maps to be played for their events/tournaments all at once. This eliminates the need to return to console after each race to load the next map. Ex: To start a sneaker cup:\
\"addq 'clearscores;map map06';addq 'map map07';addq 'map map08';addq 'map map09';addq 'map map10'\"\
There are more applications beyond this with a little creativity. See the message board post. \135-cg"
    }
    
    local text = help[command]
    if command == nil or text == nil then
        if text == nil then
            CONS_Printf(user,"Not a valid cq_command")
        end
        for key,value in ipairs(help_help) do
            CONS_Printf(user,value)
        end
    else
        CONS_Printf(user,text)
    end
end

local queue = ManagedList.new()
local queueable = Set.new()

local function getAllQueued()
    return ManagedList.getAllItems(queue)
end

local function getAllQueuedMaps(user)
    local maps = {}
    for i,cmd in ipairs(ManagedList.getAllItems(queue)) do
        if cmd:sub(1,4) != "map " then continue end
        local mapstr = cmd:sub(5)
        local map = one_match_or_print(user,{mapstr})
        table.insert(maps,map)
    end
    return maps
end

local function queueHasMaps(user)
    local maps = getAllQueuedMaps(user)
    return #maps > 0
end
rawset(_G, "cq_getallitems", getAllQueued)
rawset(_G, "cq_getallmaps", getAllQueuedMaps)
rawset(_G, "cq_hasmaps", queueHasMaps)

-- From hostmod::vote.lua by Tyron. 
-- https://hyuu.cc/hostmod/
local function make_queueable(p, ...)
	if not ... then
		CONS_Printf(p, "Supply a command to be whitelisted for vote.")
		return
	end
	local target = table.concat({...}, " ")
	if target:match(" ") then
		CONS_Printf(p, "Supply just the root command, please.")
		return
	end
    Set.add(queueable,target)
	CONS_Printf(p, "Added \130"..target.."\128 to the queueable list.")
    
end

local uber_restricted_list = {"clearbans","demote","password","promote","login","ban","banip","cq_whitelist"}
local uber_restricteds = Set.new()
for _,cmd in ipairs(uber_restricted_list) do
    Set.add(uber_restricteds,cmd)
end

local function queue_eligible(initiator,command)
    local commands = strsplit(command,";")
    for _,cmd in pairs(commands) do
        cmd = cmd:gsub("'", '"') -- Let's at least theoretically let people pass in quotes...
        -- Find what "base" cmd is being invoked and check it against the whitelist.
        local spaceindex = string.find(cmd, " ", 0, true)
        local commandfrag = cmd
        if spaceindex then
            commandfrag = cmd:sub(0, spaceindex - 1)
        end
        if not Set.contains(queueable,commandfrag) then
            CONS_Printf(initiator, "Command \130"..commandfrag.."\128 isn't whitelisted for queuing.")
            return false
        end
        if Set.contains(uber_restricteds,commandfrag) then
            CONS_Printf(initiator,"Nope :) I'm not queuing that. Even if whitelisted. Admins: execute this command directly.")
            CONS_Printf(initiator,"Command \130"..commandfrag.."\128 should never be queued.")
            return false
        end
    end
    return true
end

local function showEnableMsg(user)
    CONS_Printf(user,"'cq_commandqueue 1' to enable (currently disabled)")
end

local function inputIsJustMaps(args)
    local function all_length_two(args_)
        for i,arg in pairs(args_) do
            if arg:len() != 2 then
                return false
            end
        end
        return true
    end
    local function all_ext_mapids(args_)
        for i,arg in pairs(args_) do
            if arg:len() != 5 or string.lower(arg:sub(1,3)) != "map" then
                return false
            end
        end
        return true
    end
    return all_length_two(args) or all_length_two(strsplit(args[1]," ")) or all_ext_mapids(args) or all_ext_mapids(strsplit(args[1]," "))
end

-- copying ATO functionality because damn it's so much easier. Hats off, Onyo.
local function interpretCommandInput(p,...)
    -- Possible ways a user could input a command:
    -- "map", "map01", "map02"
    -- "map", "01", "02"
    -- "map", "map01 map02"
    -- "map", "01 02"
    -- "map map01 map02"
    -- "map 01 02"
    -- "map01", "map02"
    -- "01", "02"
    -- "map01 map02"
    -- "01 02"
    -- "map", "green", "hills"
    -- "map", "green hills"
    -- "map green hills"
    -- "forceskin", "sonic"
    -- "forceskin sonic"


    local args = {...}
    local commands = {}
    -- local ismapcommand = false
    local maplist = {}
    -- check if "map" is the command
    if inputIsJustMaps(args) then
        if #args == 1 then
            maplist = strsplit(args[1]," ")
        else
            maplist = args
        end
    elseif args[1]:sub(1,3) == string.lower("map") then
        local mapquery_detected = false
        local mapquery_str = ""
        for i,arg in ipairs(args) do
            for j, frag in ipairs(strsplit(arg," ")) do
                if mapquery_detected then
                    mapquery_str = $.." "..frag
                    continue
                end
                if i == 1 and frag == "map" then continue end
                if #frag == 2 or (#frag == 5 and frag:sub(1,3) == "map") then
                    table.insert(maplist,frag)
                    continue
                end
                mapquery_detected = true
                mapquery_str = frag
            end
        end
        if mapquery_detected then
            local map = one_match_or_print(p,strsplit(mapquery_str," "))
            if map != nil then
                table.insert(maplist,map.extid:lower())
            end
        end
    else
        -- it's not a map command
        commands = table.concat(args," ")
        -- print(commands)
        return {commands}
    end


    -- if string.lower(args[1]) == "map" then
    --     -- can't be bothered to find the correct syntax sugar. GPT solution not working
    --     for i, arg in ipairs(args) do
    --         if i == 1 then continue end
    --         table.insert(maplist,arg)
    --     end
    -- elseif args[1]:sub(1,4) == string.lower("map ") then
    --     maplist = strsplit(args[1]:sub(4)," ")
    -- elseif inputIsJustMaps(args) then
    --     if #args == 1 then
    --         maplist = strsplit(args[1]," ")
    --     else
    --         maplist = args
    --     end
    -- else
    --     -- it's not a map command
    --     commands = table.concat(args," ")
    --     -- print(commands)
    --     return {commands}
    -- end

    for i,map in ipairs(maplist) do
        if map:len() == 2 then
            map = "map"..map
        end
        table.insert(commands,"map "..map)
    end

    return commands

        
end

local function addToQueue(user,command)
    if not enabled.value then 
        showEnableMsg(user)
        return 
    end
    local command_good = ensureArg(user,command,"command",1,false)
    if not command_good then
        return
    end
    if not queue_eligible(user,command) then
        return
    end
    -- addToQueueAt(user,queue::size,command)
    ManagedList.pushright(queue,command)
end

local function popQueue(user)
    if not (enabled.value) then
        showEnableMsg(user)
        return
    end
    if ManagedList.isEmpty(queue) then
        CONS_Printf(user,"Queue is empty. 'addq \133[your command]\128' to populate your queue")
        return
    end
    local command = ManagedList.popleft(user,queue).value
    COM_BufInsertText(user,command)
end

local function showQueue_old(user)
    local cur = queue.first
    local idx = 0
    
    if not enabled.value then
        CONS_Printf(user,"Warning: queue is currently disabled. 'cq_commandqueue 1' to enable")
    end
    
    if cur > queue.last then
        CONS_Printf(user,"<empty queue>")
        return
    end
    
    while (cur <= queue.last) do
        local item = queue[cur]
        local output = "{"..idx.."}: " .. item
        CONS_Printf(user,output)
        idx = $ + 1
        cur = $ + 1
    end
    
end    

local function showQueue(user)
    if not enabled.value then
        CONS_Printf(user,"Warning: queue is currently disabled. 'cq_commandqueue 1' to enable")
    end
    local is_empty = true
    local cmds = ManagedList.getAllItems(queue)
    for i,cmd in ipairs(cmds) do
        is_empty = false
        local output = "{"..(i-1).."}: "
        if cmd:sub(1,4) != "map " then 
            CONS_Printf(user,output..cmd)
            continue
        end
        local mapstr = cmd:sub(5)
        local map = one_match_or_print(user,{mapstr})
        CONS_Printf(user,output.."map "..map.name)
    end
    if is_empty then
        CONS_Printf(user,"<empty list>")
    end
end

local function addToQueueAt(user,index,command)
    if not (enabled.value) then
        showEnableMsg(user)
        return
    end
    local index_good = ensureArg(user,index,"index",1,true)
    local command_good = ensureArg(user,command,"command",2,false)
    if not index_good or not command_good then
        return
    end
    if not queue_eligible(user,command) then
        return
    end
    index = tonumber(index)
    ManagedList.insertAt(user,queue,index,command)
end

local function addToQueueAtFront(user,command)
    if not (enabled.value) then
        showEnableMsg(user)
        return
    end
    local command_good = ensureArg(user,command,"command",1,false)
    if not command_good then
        return
    end
    if not queue_eligible(user,command) then
        return
    end
    addToQueueAt(user,0,command)
end

local function removeFromQueueAt(user,index)
    if not (enabled.value) then
        showEnableMsg(user)
        return
    end
    local index_good = ensureArg(user,index,"index",1,true)
    if not index_good then
        return
    end
    index = tonumber(index)
    ManagedList.removeAt(user,queue,index)
end

local function clearQueue(user,forced)
    if not (enabled.value) then
        showEnableMsg(user)
        return
    end
    
    if forced != "-force" then
        CONS_Printf(user,"Are you sure? Queue cannot be recovered. 'clearq -force' to clear the queue")
        return
    end
    
    ManagedList.clear(user,queue)
end

local function editQueueAt(user,index,command)
    if not (enabled.value) then
        showEnableMsg(user)
        return
    end
    local index_good = ensureArg(user,index,"index",1,true)
    local command_good = ensureArg(user,command,"command",2,false)
    if not index_good or not command_good then
        return
    end
    if not queue_eligible(user,command) then
        return
    end
    index = tonumber(index)
    ManagedList.editAt(user,queue,index,command)
end

local function addToQueue_(user,...)
    local commands = interpretCommandInput(user,...)
    for i,cmd in ipairs(commands) do
        addToQueue(user,cmd)
    end
end

local function addToQueueAt_(user,index,...)
    local commands = interpretCommandInput(user,...)
    for i,cmd in ipairs(commands) do
        addToQueueAt(user,index + (i-1),cmd)
    end
end

local function addToQueueAtFront_(user,...)
    addToQueueAt_(user,0,...)
end

local function editQueueAt_(user,index,...)
    local commands = interpretCommandInput(user,...)
    for i,cmd in ipairs(commands) do
        if i == 1 then
            editQueueAt(user,index,cmd)
        else
            addToQueueAt(user,index + (i-1),cmd)
        end
    end
end

local function test_interpretCommandInput(user)
    local testnum = 0
    local function printOutputValue(obj)
        for i,o in ipairs(obj) do
            print(i.." : "..o)
        end
    end
    local function runTest(input,expected)
        testnum =$+1
        local output = interpretCommandInput(user,unpack(input))
        local testfailed = false
        if #output != #expected then
            testfailed = true
        end

        for i=1,#expected do
            if output[i] != expected[i] then
                testfailed = true
                break
            end
        end

        if testfailed then
            print("Test failure on test "..testnum)
            print("Expected:")
            printOutputValue(expected)
            print("Actual:")
            printOutputValue(output)
        end
    end

    local basic = {"map map01","map map02"}
    runTest({"map","map01","map02"},basic)
    runTest({"map","01","02"},basic)
    runTest({"map","map01 map02"},basic)
    runTest({"map","01 02"},basic)
    runTest({"map map01 map02"},basic)
    runTest({"map 01 02"},basic)
    runTest({"map01","map02"},basic)
    runTest({"01","02"},basic)
    runTest({"map01 map02"},basic)
    runTest({"01 02"},basic)
    runTest({"map","green","hills"},{"map map01"})
    runTest({"map","green hills"},{"map map01"})
    runTest({"map green hills"},{"map map01"})
    runTest({"map","chao","circuit"},{})
    runTest({"map","chao circuit"},{})
    runTest({"map chao circuit"},{})

    print("done running tests")
end

local check_hmvotetimer = 0
local suggester = ""
local queuerequest = ""
local suggestedmap = ""
local voteisasuggestion = false
addHook("ThinkFrame", function()
    if not server.HMvtimer then
        voteisasuggestion = false
    end
	if not check_hmvotetimer then return end
    check_hmvotetimer = $-1
    if server.HMvtimer then
        check_hmvotetimer = 0
        voteisasuggestion = true
        local msg = "\131"..suggester.." would like to "..queuerequest.." Use suggestq in console to submit a suggestion."
        chatprint(msg)
    end
end)

hud.add(function(v,p)
    if server.HMvtimer and voteisasuggestion then
        local patchName = suggestedmap.extid.."P"
        local mapp = v.patchExists(patchName) and v.cachePatch(patchName) or v.cachePatch("BLANKLVL")
        v.drawScaled(269 * FRACUNIT,104 * FRACUNIT,(25 * FRACUNIT) / 100,mapp,V_SNAPTORIGHT|V_SNAPTOBOTTOM)
        v.drawString(309,124,"map: "..suggestedmap.name,V_ALLOWLOWERCASE|V_SNAPTORIGHT|V_SNAPTOBOTTOM,"small-right")
    end
end, "game")

local function suggest(user,...)
    if hm_color == nil then 
        CONS_Printf(user,"Cannot work without hostmod loaded :(")
        return
    end
    
    if server.HMvtimer then 
        CONS_Printf(user,"There's currently another vote going on")
        return
    end
    
    if not allow_suggestq.value then
        CONS_Printf(user,"suggestq is not allowed. In console, `cq_allowsuggestq 1` to enable.")
        return
    end

    local args = {...}
    if #args == 0 then
        CONS_Printf(user,"usage: `suggestq QUERY` replace QUERY with the name of the map you want to play. A vote will be called.")
        return
    end
    local map = one_match_or_print(user,{...})
    if map == nil then return end
    local queueornext = nil
    if queueHasMaps(user) then
        queueornext = "add \130"..map.name.."\131 to the queue of maps to play.\128"
    else
        queueornext = "play on \130"..map.name.."\131 next.\128"
    end

    local cmd = "vote \"addq "..map.extid
    COM_BufInsertText(user,cmd)
    check_hmvotetimer = TICRATE
    suggester = user.name
    queuerequest = queueornext
    suggestedmap = map
    -- if server.HMvtimer then
    --     local msg = "\131"..user.name.." would like to "..queueornext.." Use suggestq in console to submit a suggestion."
    --     chatprint(msg)
    -- end
end

-- From hostmod::automate.lua by Tyron. 
-- https://hyuu.cc/hostmod/
local RS_THINK, RS_VOTE, RS_INT = 1, 2, 3
local roundstatus = RS_THINK
addHook("ThinkFrame", function()
	roundstatus = RS_THINK
end)
addHook("IntermissionThinker", function()
	roundstatus = RS_INT
end)
addHook("VoteThinker", function()
	if not popOnVote.value then return end
	if roundstatus != RS_VOTE then
		COM_BufAddText(server, "popq")
	end
	roundstatus = RS_VOTE
end)

addHook("NetVars", function(network)
    queue = network(queue)
    queueable = network(queueable)
end)

COM_AddCommand("addq",addToQueue_,COM_ADMIN)
COM_AddCommand("popq",popQueue,COM_ADMIN)
COM_AddCommand("showq",showQueue)
COM_AddCommand("deleteq",removeFromQueueAt,COM_ADMIN)
COM_AddCommand("insertq",addToQueueAt_,COM_ADMIN)
COM_AddCommand("editq",editQueueAt_,COM_ADMIN)
COM_AddCommand("addfrontq",addToQueueAtFront_,COM_ADMIN)
COM_AddCommand("clearq",clearQueue,COM_ADMIN)
COM_AddCommand("helpq",showHelp)
COM_AddCommand("suggestq",suggest)
COM_AddCommand("cq_whitelist", make_queueable, COM_ADMIN)
COM_AddCommand("cq_testinternal", test_interpretCommandInput)

rawset(_G,"cq_version","2.1")
print("commandqueue has been loaded. Type helpq in console for more info.")
if HM_Scoreboard_AddTip != nil then
    print("Added Hostmod tips")
    HM_Scoreboard_AddTip("the suggestq console command allows you to suggest a map the lobby should play next!")
    HM_Scoreboard_AddTip("`suggestq green hills` will call a vote on whether to play green hills next. Of course you could put any map on there...")
    HM_Scoreboard_AddTip("Is the whole lobby itchting to play on a particular map? use suggestq in console to make it happen!!")
end