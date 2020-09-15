#if defined _avatars_included
	#endinput
#endif
#define _avatars_included

#if !defined _files_included
	#include <files>
#endif

#define AVATAR_HEIGHT_SIZE 64
#define AVATAR_WIDTH_SIZE 64
#define AVATAR_PIXEL_CELL_SIZE 3
#define AVATAR_IMAGE_SIZE AVATAR_HEIGHT_SIZE * AVATAR_WIDTH_SIZE * AVATAR_PIXEL_CELL_SIZE

/**
 * Sets the player avatar.
 *
 * @param iClient        Client index.
 * @param sAvatarContent RGB file content.
 * @param bPriority      Whether to sets the avatar if it is set 
 *                       by another plugin.
 *
 * @return               Avatar is sets.
 *
 * @error                Invalid client index, is not connected, or is fake.
 */
native bool SetPlayerAvatar(int iClient, const char sAvatarContent[AVATAR_IMAGE_SIZE], bool bPriority = false);

/**
 * Sets the player avatar from file.
 *
 * @param iClient        Client index to affect.
 * @param sAvatarFile    Avatar file in RGB format for sets.
 * @param bPriority      Whether to sets the avatar if it is set 
 *                       by another plugin.
 *
 * @return               If there are no problems with the file 
 *                       and the avatar is sets.
 *
 * @error                Invalid client index, is not connected, or is fake.
 */
native bool SetPlayerAvatarFromFile(int iClient, const char sAvatarFile[PLATFORM_MAX_PATH], bool bPriority = false);

/**
 * Gets the player avatar.
 *
 * @param iClient        Client index.
 * @param sAvatarContent RGB file content. It will be recorded.
 *
 * @return               Avatar is writes.
 *
 * @error                Invalid client index.
 */
native bool GetPlayerAvatar(int iClient, char sAvatarContent[AVATAR_IMAGE_SIZE]);

/**
 * Sets the player avatar.
 *
 * @param sAvatarFile    Avatar file in RGB format.
 * @param sAvatarContent RGB file content. It will be recorded.
 *
 * @return               Avatar is writes.
 */
native bool LoadAvatarFromFile(const char sAvatarFile[PLATFORM_MAX_PATH], char sAvatarContent[AVATAR_IMAGE_SIZE]);

/**
 * Refreshed the avatar cache.
 *
 * @param sAvatarFile    Avatar file in RGB format.
 *
 * @noreturn
 */
native void RefreshAvatarFileCache(const char sAvatarFile[PLATFORM_MAX_PATH]);



public SharedPlugin __pl_avatar_changer = 
{
	name = "avatar_changer",
	file = "avatar_changer.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_avatar_changer_SetNTVOptional()
{
	MarkNativeAsOptional("SetPlayerAvatar");
	MarkNativeAsOptional("SetPlayerAvatarFromFile");
	MarkNativeAsOptional("GetPlayerAvatar");
	MarkNativeAsOptional("LoadAvatarFromFile");
	MarkNativeAsOptional("RefreshAvatarFileCache");
}
#endif