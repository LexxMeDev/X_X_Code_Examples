using DevAssistent.Controllers.Developers;
using DevAssistent.Core.Bases;
using DevAssistent.Core.Services.MessageServices;
using DevAssistent.Core.Services.MessageServices.Interfaces;
using DevAssistent.DataStructures;
using DevAssistent.DataStructures.Enums;
using DevAssistent.DataStructures.Settings;
using DevAssistent.DataStructures.Transfer.Configs.Markets;
using DevAssistent.DataStructures.Transfer.Configs.Markets.Bases;
using DevAssistent.DataStructures.Transfer.Configs.Socials;
using DevAssistent.Helpers;
using DevAssistent.MessageSystem;
using DevAssistent.Providers;
using DevAssistent.Services.MainThread;
using UnityEngine;

#if UNITY_WEBGL && BEST_TEAM__CRAZY_GAMES
using CrazyGames;
#endif

namespace DevAssistent.Services.Root
{
    public class GameServices : DevAssistent.Core.Bases.Singleton<GameServices>
#if UNITY_WEBGL && BEST_TEAM__CRAZY_GAMES
        , IMessageSubscriber<Messages.Environment.InitializedCrazyGamesSdk>
#endif
    
#if UNITY_WEBGL && (BEST_TEAM__GAME_MONETIZE || BEST_TEAM__GAME_DISTRIBUTION)
        , IMessageSubscriber<Messages.Ads.RewardVideo.Showed>
#endif
    {
        public static bool IsMobileDevice { get; private set; }
        public static string ConfigsUrl => Constants.GetConfigsUrl(Config.GetRemoteUrl(Market), Market);
        public static string BundlesUrl => Constants.GetBundlesUrl(Config.GetRemoteUrl(Market));
        public static MarketType Market => Config.IsNullOrDead() ? MarketType.Yandex : Config.Market;
        public static InstanceProperties InstancePropertiesConfig => Config.GetMarketConfig(Config.Market).InitializeApp;
        public static SocialConfig SocialConfig => Config.GetMarketConfig(Config.Market).SocialConfig;

        private static BEST_TEAM_Config _config;
        public static BEST_TEAM_Config Config => _config.IsNullOrDead()
            ? _config = Resources.Load<BEST_TEAM_Config>(Constants.SdkConfigPath)
            : _config;
        
        public static BaseMarketConfig MarketConfig => Config.IsNullOrDead() ? null : Config.GetMarketConfig();

#if (BEST_TEAM__GAME_MONETIZE || BEST_TEAM__GAME_DISTRIBUTION) && UNITY_WEBGL
        private bool _isShowedRewardVideo;
#endif
        
        protected override void Awake()
        {
            base.Awake();
            
#if BEST_TEAM__CRAZY_GAMES == false
            IsMobileDevice = WasMobilePlatform();
#endif
            if (Config.DebugSettings.EnableDeveloperConsole)
                DeveloperConsoleController.Initialize();
        }

        private void OnEnable()
        {
#if BEST_TEAM__GAME_MONETIZE && UNITY_WEBGL
            GameMonetize.OnResumeGame += ResumeGame;
            GameMonetize.OnPauseGame += PauseGame;
#endif

#if BEST_TEAM__GAME_DISTRIBUTION && UNITY_WEBGL
            GameDistribution.OnResumeGame += ResumeGame;
            GameDistribution.OnPauseGame += PauseGame;
#endif
            
#if (BEST_TEAM__GAME_MONETIZE || BEST_TEAM__GAME_DISTRIBUTION || BEST_TEAM__CRAZY_GAMES) && UNITY_WEBGL
            MessageService.Subscribe(this);
#endif
        }

        private void OnDisable()
        {
#if BEST_TEAM__GAME_MONETIZE && UNITY_WEBGL
            GameMonetize.OnResumeGame -= ResumeGame;
            GameMonetize.OnPauseGame -= PauseGame;
#endif

#if BEST_TEAM__GAME_DISTRIBUTION && UNITY_WEBGL
            GameDistribution.OnResumeGame -= ResumeGame;
            GameDistribution.OnPauseGame -= PauseGame;
#endif
            
#if (BEST_TEAM__GAME_MONETIZE || BEST_TEAM__GAME_DISTRIBUTION || BEST_TEAM__CRAZY_GAMES) && UNITY_WEBGL
            MessageService.Unsubscribe(this);
#endif
        }
        
#if (BEST_TEAM__GAME_MONETIZE || BEST_TEAM__GAME_DISTRIBUTION) && UNITY_WEBGL
        public void OnMessage(Messages.Ads.RewardVideo.Showed message)
        {
            _isShowedRewardVideo = true;
        }
        
        private void ResumeGame()
        {
            MainThreadService.Enqueue(() =>
            {
                if (_isShowedRewardVideo)
                {
                    Messages.Ads.RewardVideo.Closed.Publish();
                    _isShowedRewardVideo = false;
                    return;
                }
                
                Messages.App.FocusOnApp.ChangedFromGameServices.Publish(true);
            });
        }
        
        private void PauseGame()
        {
            MainThreadService.Enqueue(() => Messages.App.FocusOnApp.ChangedFromGameServices.Publish(false));
        }
#endif
}
