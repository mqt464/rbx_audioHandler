local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local directory = replicatedStorage:FindFirstChild("audio")
local audio = {}

local function getAudioFolder(): Folder?
	if directory then
		return directory
	end

	if runService:IsServer() then
		directory = Instance.new('Folder')
		directory.Name = "audio"
		directory.Parent = replicatedStorage
		return directory
	end

	warn('audio directory cannot be created on the client. Instance the folder before runtime or on the server.')
	return nil
end

local function resolveKeyPath(key: string): (Folder?, string)
	local segments = key:split(".")
	local settingName = table.remove(segments, #segments)
	local root = getAudioFolder()
	if not root then return nil, "" end

	local current = root
	for _, segment in ipairs(segments) do
		local child = current:FindFirstChild(segment)
		if not child then
			if runService:IsServer() then
				child = Instance.new("Folder")
				child.Name = segment
				child.Parent = current
			else
				warn(`Folder "{segment}" does not exist in audio path "{key}"`)
				return nil, ""
			end
		end

		if not child:IsA("Folder") then
			warn(`Invalid namespace structure for key "{key}"`)
			return nil, ""
		end

		current = child
	end

	return current, settingName
end

local function getSound(key: string): Sound?
	local folder, name = resolveKeyPath(key)
	if folder then
		local sound = folder:FindFirstChild(name)
		if sound and sound:IsA("Sound") then
			return sound
		end
	end
end

function audio.create(key: string, rbxAssetId: string): Sound
	assert(runService:IsServer(), "audio.create must be called on the server")
	local parentFolder, soundName = resolveKeyPath(key)
	if not parentFolder then
		error(`Failed to resolve key path: {key}`)
	end

	local existing = parentFolder:FindFirstChild(soundName)
	if existing and existing:IsA("Sound") then
		return existing
	end

	local sound = Instance.new("Sound")
	sound.Name = soundName
	sound.SoundId = "rbxassetid://" .. rbxAssetId
	sound.Parent = parentFolder

	return sound
end

function audio:play(key: string, audioProperties: {[string]: any}?)
	local root = getAudioFolder()
	if not root then
		warn("Audio folder not found")
		return
	end

	local segments = key:split(".")
	local soundName = table.remove(segments, #segments)
	local current = root

	for _, segment in ipairs(segments) do
		local nextFolder = current:FindFirstChild(segment)
		if not nextFolder or not nextFolder:IsA("Folder") then
			warn(`Invalid folder path for key "{key}"`)
			return
		end
		current = nextFolder
	end

	local sound = current:FindFirstChild(soundName)
	if not sound or not sound:IsA("Sound") then
		warn(`Sound "{key}" not found`)
		return
	end

	if audioProperties then
		for prop, val in pairs(audioProperties) do
			pcall(function()
				sound[prop] = val
			end)
		end
	end

	sound:Play()
end

function audio:quickPlay(key: string, audioProperties: {[string]: any}?)
	local sound = getSound(key)
	if not sound then return end

	local toPlay =  sound:Clone()
	toPlay.Parent = sound.Parent or workspace
	toPlay.Ended:Connect(function() toPlay:Destroy() end)
	
	-- apply props
	if audioProperties then
		for prop, val in pairs(audioProperties) do
			pcall(function()
				toPlay[prop] = val
			end)
		end
	end
	toPlay:Play()
end

function audio:stop(key: string)
	local sound = getSound(key)
	if sound and sound.IsPlaying then
		sound:Stop()
	end
end

function audio:preload(key: string)
	local sound = getSound(key)
	if sound then
		game:GetService("ContentProvider"):PreloadAsync({sound})
	end
end

function audio:listAll(): {string}
	local sounds = {}
	local function recurse(folder, path)
		for _, child in pairs(folder:GetChildren()) do
			if child:IsA("Folder") then
				recurse(child, path .. "." .. child.Name)
			elseif child:IsA("Sound") then
				table.insert(sounds, path .. "." .. child.Name)
			end
		end
	end
	local root = getAudioFolder()
	if root then recurse(root, "audio") end
	return sounds
end

function audio:setCategoryVolume(category: string, volume: number)
	local root = getAudioFolder()
	if not root then return end
	local folder = root:FindFirstChild(category)
	if folder then
		for _, sound in folder:GetDescendants() do
			if sound:IsA("Sound") then
				sound.Volume = volume
			end
		end
	end
end

function audio:fadeOut(key: string, duration: number)
	local sound = getSound(key)
	if not sound then return end
	local startVolume = sound.Volume
	task.spawn(function()
		local t = 0
		while t < duration do
			t += task.wait()
			sound.Volume = startVolume * (1 - t/duration)
		end
		sound:Stop()
		sound.Volume = startVolume
	end)
end

return audio
