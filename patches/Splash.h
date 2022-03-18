#pragma once

#include <string>
#include "components/ImageComponent.h"
#include "components/TextComponent.h"

// Getting the user's home dir
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>

class Window;
class TextureResource;

// TODO: this is hardcoded path is shit, needs to be fixed

#if WIN32
#define DEFAULT_SPLASH_IMAGE ":/splash.svg"
#define OLD_SPLASH_LAYOUT true
#else
#define DEFAULT_SPLASH_IMAGE "./res/logo.png"
#define OLD_SPLASH_LAYOUT false
#endif

class Splash
{
public:
	Splash(Window* window, const std::string image = DEFAULT_SPLASH_IMAGE, bool fullScreenBackGround = true);
	~Splash();

	void update(std::string text, float percent = -1);
	void render(float opacity, bool swapBuffers = true);

private:
	ImageComponent  mBackground;
	TextComponent   mText;
	float			mPercent;

	ImageComponent  mInactiveProgressbar;
	ImageComponent  mActiveProgressbar;

	unsigned int	mBackgroundColor;
	float			mRoundCorners;

	std::shared_ptr<TextureResource> mTexture;

	std::vector<GuiComponent*> mExtras;
} ;