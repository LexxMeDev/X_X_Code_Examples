using System;
using System.Collections.Generic;
using DevAssistent.Helpers;
using SomeProject.Controllers;
using SomeProject.DataStructures.Enums;
using SomeProject.DataStructures.Transfer;
using SomeProject.DataStructures.Transfer.Configs.UI;
using SomeProject.Managers.Bases;
using SomeProject.Managers.Interfaces;
using SomeProject.UI.Bases;
using SomeProject.UI.Interfaces;
using SomeProject.UI.Windows;
using SomeProject.UI.Windows.Cheats;
using SomeProject.UI.Windows.Info;
using SomeProject.UI.Windows.MainMenu;
using SomeProject.UI.Windows.Playing;
using SomeProject.UI.Windows.RateGame;
using SomeProject.UI.Windows.SelectLevels;
using SomeProject.UI.Windows.Settings;
using UnityEngine;
using UnityEngine.AddressableAssets;
using Object = UnityEngine.Object;

namespace SomeProject.Managers.Windows
{
    public class CommonUI : BaseManager, ICommonUI
    {
        private static WindowsConfig WindowsConfig => Root.GameConfig.WindowsConfig;
        private static IUIManager UIManager => Root.UIManager;
        private static IAnalyticsManager AnalyticsManager => Root.AnalyticsManager;

        private PlayingWindow _playingWindow;

        [SerializeField] private float delayForShowOffer;

        private int _showOfferCounter;
        private bool _showedFirstOffer;
        private readonly Queue<string> _showedOffers = new Queue<string>();
        
        public void ShowMainMenuWindow(bool dontShowOffer = false)
        {
            ShowWindow<MainMenuWindow>();
            
            if(_showOfferCounter == 0 && !dontShowOffer)
            {
                _showedFirstOffer = true;
                StartCoroutine(CoroutineHelper.DelayIEnumerator(delayForShowOffer, () =>
                {
                    if (Root.PlayerProgress.LevelsProgress.Level > 1)
                        Root.OffersManager.ShowOffer(PlaceForOffersType.TheFirstShowMainMenu);
                }));
            } else if (_showOfferCounter > 0 && !dontShowOffer)
            {
                StartCoroutine(CoroutineHelper.DelayIEnumerator(delayForShowOffer, () =>
                {
                    if (Root.PlayerProgress.LevelsProgress.Level > 1)
                        Root.OffersManager.ShowOffer(PlaceForOffersType.CommonShowMainMenu);
                }));
            }

            _showOfferCounter++;
        }

        public void CloseMainMenuWindow()
        {
            CloseWindow<MainMenuWindow>();
        }

        public void ShowSelectLevelWindow()
        {
            ShowWindow<SelectLevelWindow>();
        }

        public void CloseSelectLevelWindow()
        {
            CloseWindow<SelectLevelWindow>();
        }

        public void ShowPlayingWindow()
        {
            _playingWindow = ShowWindow<PlayingWindow>();
        }

        public void ClosePlayingWindow()
        {
            _playingWindow = null;
            CloseWindow<PlayingWindow>();
        }

        public void ShowSettingsWindow()
        {
            ShowWindow<SettingsWindow>();
        }

        public void CloseSettingsWindow()
        {
            CloseWindow<SettingsWindow>();
        }

        public void ShowRateTheGameWindow()
        {
            ShowWindow<RateTheGameWindow>();
        }

        public void CloseRateTheGameWindow()
        {
            CloseWindow<RateTheGameWindow>();
        }

        public LoadingWindow ShowLoadingWindow()
        {
            return ShowWindow<LoadingWindow>();
        }

        public void CloseLoadingWindow()
        {
            CloseWindow<LoadingWindow>();
        }

        public InfoWindow ShowInfoWindow()
        {
            return ShowWindow<InfoWindow>();
        }

        public void CloseInfoWindow()
        {
            CloseWindow<InfoWindow>();
        }

        public void ShowOverlayWindow(Action middleAnimationAction)
        {
            ShowWindow<OverlayWindow>(true).HandlerMiddleAnimation(middleAnimationAction);
        }

        public void CloseOverlayWindow()
        {
            CloseWindow<OverlayWindow>(true);
        }

        public void ShowItemSelector(List<ItemVariantConfig> items, Action<ItemVariantConfig> onClick)
        {
            if (!_playingWindow.IsNullOrDead())
            {
                _playingWindow.StageItemSelector.gameObject.SetActive(true);
                _playingWindow.StageItemSelector.SetItemVariants(items, onClick);
            }
        }

        public void CloseItemSelector()
        {
            _playingWindow.StageItemSelector.gameObject.SetActive(false);
        }
        
        public void ShowCheatWindow()
        {
            ShowWindow<CheatsWindow>();
        }

        public void CloseCheatWindow()
        {
            CloseWindow<CheatsWindow>();
        }

        public Prehistory.Base.Prehistory ShowPrehistory(GameObject prehistoryWindowPrefab)
        {
            return UIManager.ShowWindow<Prehistory.Base.Prehistory>(prehistoryWindowPrefab);
        }

        public void ClosePrehistory(string prehistoryName)
        {
            UIManager.CloseWindow(prehistoryName);
        }

        public void ShowOfferWindow(string offerId)
        {
            var (prefab, reference) = GetOfferPrefab(offerId);
            if(prefab == null && reference == null) return;
            
            AnalyticsManager.ShowOffer(offerId);

            if (prefab != null)
                UIManager.ShowWindow<BaseOfferWindow>(prefab, true);
            else
                UIManager.ShowWindow<BaseOfferWindow>(reference, true);
            
            _showedOffers.Enqueue(offerId);
        }

        public void CloseOfferWindow()
        {
            var offerId = _showedOffers.Dequeue();
            
            AnalyticsManager.HideOffer(offerId);
            
            var (prefab, reference) = GetOfferPrefab(offerId);
            if (prefab != null) UIManager.CloseWindow(offerId, true);
            else UIManager.CloseWindow(reference, true);

            if (_showedFirstOffer)
            {
                _showedFirstOffer = false;
                StartCoroutine(CoroutineHelper.DelayIEnumerator(delayForShowOffer, () =>
                    Root.OffersManager.ShowOffer(PlaceForOffersType.TheFirstShowMainMenuAfterOffer)));
            }
        }

        public string GetShowedOfferId()
        {
            if(_showedOffers == null || _showedOffers.Count == 0) return string.Empty;
            return _showedOffers.Peek();
        }
        
        public void ShowCustomizationSelector()
        {
            _playingWindow.CustomizationManager.gameObject.SetActive(true);
        }

        public void CloseCustomizationSelecor()
        {
            _playingWindow.CustomizationManager.gameObject.SetActive(false);
        }

        public PlayingWindow GetPlayingWindow()
        {
            return _playingWindow;
        }

        private (GameObject, AssetReference) GetOfferPrefab(string offerId)
        {
            var windowConfig = WindowsConfig.Window.Find(item => item.Id == offerId);
            return (windowConfig.WindowPrefab, windowConfig.Reference);
        }

        #region Common

        private T ShowWindow<T>(bool isOverlay = false) where T : Object
        {
            var windowName = typeof(T).Name;
            var windowPrefab = WindowsConfig.GetWindowPrefab(windowName);
            
            AnalyticsManager.ShowWindow(windowPrefab.name.Replace("(Clone)", ""));
            
            return UIManager.ShowWindow<T>(windowPrefab, isOverlay);
        }

        private void CloseWindow<T>(bool isOverlay = false) where T : Object
        {
            var windowName = typeof(T).Name;
            
            AnalyticsManager.HideWindow(windowName);
            
            UIManager.CloseWindow(windowName, isOverlay);
        }

        #endregion
    }
}