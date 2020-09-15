# Avatar-Changer
SourceMod plugin that changes avatars for players

Instructions for converting avatars
------------
1. Search for the desired avatars in the `.png` format
2. Compress them to a resolution of 64x64 px
3. Upload images to the client side in `avatars/` folder (if not, create one)
4. Run the client game and enter:
``
sv_cheats 1; cl_avatar_convert_rgb
``
5. From `avatars/` folder, upload files in the `.rgb` format to the server
6. Write the paths to them in `addons/sourcemod/configs/avatars.ini`

Requirements:
------------
<a href="//github.com/komashchenko/PTaH/">PTaH</a> not lower v1.1.3