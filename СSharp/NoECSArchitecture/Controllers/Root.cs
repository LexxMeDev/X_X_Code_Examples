 using DevAssistent.Helpers;
using DevAssistent.Services.Configs;
using SomeProject.Core.Bases;
using SomeProject.DataStructures.Settings;
using SomeProject.DataStructures.Transfer;
using SomeProject.DataStructures.Transfer.Configs;
using SomeProject.Managers.Interfaces;
using SomeProject.UI.Interfaces;
using UnityEngine;

namespace SomeProject.Controllers
{
    public class Root : BaseMonoBehaviour
    {
        private static Root _instance;
        public static Root Instance => _instance;
        
        private GameConfig _gameConfig;
        public static GameConfig GameConfig => Instance._gameConfig;

        private static IUIManager _uiManager;
        private static ICommonUI _commonUI;
        private static IPlayerManager _playerManager;
        private static ISoundManager _soundManager;
        private static ILevelsManager _levelsManager;
        private static IPurchaseManager _purchaseManager;
        private static IPrestoryManager _prestoryManager;
        private static IAnalyticsManager _analyticsManager;
        private static IOffersManager _offersManager;

        private static RemoteGameConfig _remoteConfig;
        
        private static BaseFactory Factory => BaseFactory.Instance;
        public static PlayerProgress PlayerProgress => PlayerManager.PlayerProgress;

        private void Awake()
        {
            _instance = this;
            _gameConfig = Resources.Load<GameConfig>(Constants.GameConfigPath);
            DontDestroyOnLoad(gameObject);
        }
        
        public static IUIManager UIManager
        {
            get
            {
                if (_uiManager.IsNullOrDead())
                    _uiManager = Factory.GetManager<IUIManager>();
                return _uiManager;
            }
        }

        public static ICommonUI CommonUI
        {
            get
            {
                if (_commonUI.IsNullOrDead())
                    _commonUI = Factory.GetManager<ICommonUI>();
                return _commonUI;
            }
        }
        
        public static IPlayerManager PlayerManager
        {
            get
            {
                if (_playerManager.IsNullOrDead())
                    _playerManager = Factory.GetManager<IPlayerManager>();
                return _playerManager;
            }
        }
        public static ISoundManager SoundManager
        {
            get
            {
                if (_soundManager.IsNullOrDead())
                    _soundManager = Factory.GetManager<ISoundManager>();
                return _soundManager;
            }
        }

        public static ILevelsManager LevelsManager
        {
            get
            {
                if (_levelsManager.IsNullOrDead())
                    _levelsManager = Factory.GetManager<ILevelsManager>();
                return _levelsManager;
            }
        }

        public static IPurchaseManager PurchaseManager
        {
            get
            {
                if (_purchaseManager.IsNullOrDead())
                    _purchaseManager = Factory.GetManager<IPurchaseManager>();
                return _purchaseManager;
            }
        }

        public static IAnalyticsManager AnalyticsManager
        {
            get
            {
                if (_analyticsManager.IsNullOrDead())
                    _analyticsManager = Factory.GetManager<IAnalyticsManager>();
                return _analyticsManager;
            }
        }
    }
}
