using Microsoft.Extensions.Logging;

using StreamingLiveKalmanFilter.Maui.Services;

namespace StreamingLiveKalmanFilter.Maui;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
			});

		builder.Services.AddMauiBlazorWebView();
		builder.Services.AddSingleton(new HttpClient { Timeout = Timeout.InfiniteTimeSpan });
		builder.Services.AddSingleton<ControllerEventClient>();

#if DEBUG
		builder.Services.AddBlazorWebViewDeveloperTools();
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}
