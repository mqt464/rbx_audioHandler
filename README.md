# documentation created by ChatGPT because I am lazy

---

# 🔊 Roblox Audio Manager Module

A lightweight, server-compatible Roblox audio module that handles structured sound asset management, playback, and control. Sounds are stored in a `ReplicatedStorage.audio` folder and referenced via hierarchical keys (`"Music.Lobby.Theme"`).

---

## 📁 Folder Structure

Sounds are managed in a folder called `"audio"` inside `ReplicatedStorage`. You can nest folders to organise sounds into categories.

For example:

```
ReplicatedStorage
└── audio
    └── Music
        └── Lobby
            └── Theme (Sound)
```

Access this sound using the key:

```lua
"Music.Lobby.Theme"
```

---

## ✅ Features

* Automatic folder structure generation on the server
* Safe sound retrieval with namespaced string keys
* Custom property-based sound playback
* Disposable/one-shot playback (`quickPlay`)
* Volume control per category
* Audio preloading
* Fade-out utility
* Runtime sound listing

---

## 📦 API

### `audio.create(key: string, rbxAssetId: string): Sound`

Creates a `Sound` object under the key's folder structure with the given asset ID. Server-only.

```lua
local sound = audio.create("UI.Click", "123456789")
```

---

### `audio:play(key: string, properties: {[string]: any}?)`

Plays an existing sound with optional custom properties (like `Volume`, `PlaybackSpeed`, etc.).

```lua
audio:play("UI.Click", {
	Volume = 0.7,
	PlaybackSpeed = 1.2,
})
```

---

### `audio:quickPlay(key: string, properties: {[string]: any}?)`

Plays a **clone** of the sound for one-shot playback. Automatically destroys itself when finished.

```lua
audio:quickPlay("SFX.Explosion")
```

---

### `audio:stop(key: string)`

Stops a currently playing sound if it's found.

```lua
audio:stop("Music.Lobby.Theme")
```

---

### `audio:fadeOut(key: string, duration: number)`

Smoothly fades out and stops a sound over a given number of seconds.

```lua
audio:fadeOut("Music.Lobby.Theme", 2)
```

---

### `audio:preload(key: string)`

Preloads the sound to reduce playback delay.

```lua
audio:preload("SFX.Enemy.Spawn")
```

---

### `audio:listAll(): {string}`

Returns a list of all available sound keys under the `audio` folder.

```lua
for _, key in ipairs(audio:listAll()) do
	print(key)
end
```

---

### `audio:setCategoryVolume(category: string, volume: number)`

Sets the volume for all sounds within a specific category (folder).

```lua
audio:setCategoryVolume("Music", 0.5)
```

---

## 🧠 Key Notes

* This module **must** be used on the **server** when calling `create`.
* You should manually create and replicate the `"audio"` folder and its structure if using in client-only environments.
* Key strings are dot-separated paths (`"Folder1.Folder2.SoundName"`).
* Safe property setting via `pcall`.

---

## 🧪 Example

```lua
-- Server-side example
audio.create("UI.Notification", "456789123")
audio:play("UI.Notification", {Volume = 0.8})

-- Quick play SFX
audio:quickPlay("SFX.Button.Click")
```

---
