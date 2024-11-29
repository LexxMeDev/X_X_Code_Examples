using System.Collections.Generic;
using System.Linq;
using DevAssistent.Helpers;
using SomeProject.DataStructures.Settings;
using SomeProject.Managers.Bases;
using SomeProject.Managers.Interfaces;
using SomeProject.MessageSystem;
using SomeProject.UI.Bases;
using UnityEngine;

#if BEST_TEAM__ADDRESSABLES
using DevAssistent.Services.AssetsLoader;
using UnityEngine.AddressableAssets;
using DevAssistent.Core.Interfaces;
using DevAssistent.Core.Promises;
#endif

namespace SomeProject.Managers.Windows
{
    public class UIManager : BaseManager, IUIManager
    {
        private GameObject _mainLayer;
        private GameObject _overlayLayer;
        
        private GameObject MainLayer => _mainLayer.IsNullOrDead() 
            ? _mainLayer = GameObject.FindWithTag(Constants.MainLayerTag) : _mainLayer;
        private GameObject OverlayLayer => _overlayLayer.IsNullOrDead() 
            ? _overlayLayer = GameObject.FindWithTag(Constants.OverlayLayerTag) : _overlayLayer;

        [SerializeField] private List<GameObject> _mainWindows;
        [SerializeField] private List<GameObject> _overlayWindows;
#if BEST_TEAM__ADDRESSABLES
        [SerializeField] private List<AssetReference> _mainWindowsReferences;
        [SerializeField] private List<AssetReference> _overlayWindowsReferences;
#endif
        private Canvas _canvas;
        public Canvas Canvas => _canvas.IsNullOrDead() 
            ? _canvas = _mainLayer.GetComponent<Canvas>() 
            : _canvas;

        private Canvas _overlayCanvas;
        public Canvas OverlayCanvas => _overlayCanvas.IsNullOrDead()
            ? _overlayCanvas = _overlayLayer.GetComponent<Canvas>()
            : _overlayCanvas;

        public List<BaseWindow> ShowedWindows
        {
            get
            {
                var result = new List<GameObject>();
                result.AddRange(_mainWindows);
                result.AddRange(_overlayWindows);
                return result.Select(item => item.GetComponent<BaseWindow>()).ToList();
            }
        }

        public T ShowWindow<T>(GameObject windowPrefab, bool isOverlay = false, bool dontUseCanvas = false) where T : Object
        {
            if (MainLayer.IsNullOrDead())
                return null;
            
            var windowParent = isOverlay ? OverlayLayer : MainLayer;
            windowParent = dontUseCanvas ? null : windowParent;
            
            var createdWindow = CreateWindow<T>(windowPrefab, windowParent.transform, isOverlay);
            
            Messages.Windows.ShowedWindow.Publish(typeof(T).Name);
            return createdWindow;
        }

        public void CloseWindow(string windowName, bool isOverlay = false)
        {
            var windows = isOverlay ? _overlayWindows : _mainWindows;
            var index = windows.FindIndex(item => item.name == windowName);
            if (index == -1) return;
            
            Destroy(windows[index].gameObject);
            windows.RemoveAt(index);
            
            Messages.Windows.ClosedWindow.Publish(windowName);
        }
        
#if BEST_TEAM__ADDRESSABLES
        public IPromise<T> ShowWindow<T>(AssetReference windowReference, bool isOverlay = false, bool dontUseCanvas = false) where T : Object
        {
            if (MainLayer.IsNullOrDead())
                return Deferred<T>.Rejected("Not found MainLayer object.");
            
            var deferred = Deferred<T>.GetFromPool();
            var parent = isOverlay ? OverlayLayer : MainLayer;
            parent = dontUseCanvas ? null : parent;
            
            LoadWindowPrefab(windowReference).Done(window =>
            {
                CreateWindow<T>(window, parent == null ? null : parent.transform, isOverlay);

                var references = isOverlay ? _overlayWindowsReferences : _mainWindowsReferences;
                if(references.FindIndex(item => item.AssetGUID == windowReference.AssetGUID) == -1)
                    references.Add(windowReference);
                
                Messages.Windows.ShowedWindow.Publish(window.name);
                deferred.Resolve(window.GetComponent<T>());
                
            }).Fail(err => deferred.Reject(err));
            
            return deferred;
        }
#endif

#if BEST_TEAM__ADDRESSABLES
        public IPromise CloseWindow(AssetReference reference, bool isOverlay = false)
        {
            var references = isOverlay ? _overlayWindowsReferences : _mainWindowsReferences;

            var index = references.FindIndex(item => item.AssetGUID == reference.AssetGUID);
            if(index == -1)
                return Deferred.Resolved();

            var deferred = Deferred.GetFromPool();
            var windows = isOverlay ? _overlayWindows : _mainWindows;
            var windowName = windows[index].gameObject.name;
            windows[index].GetComponent<BaseWindow>()
                .CloseWindow().Always(() =>
                {
                    windows.RemoveAt(index);
                    references.RemoveAt(index);

                    reference.ReleaseAsset();
                    deferred.Resolve();

                    Messages.Windows.ClosedWindow.Publish(windowName);
                });
            
            return deferred;
        }
#endif
        
#if BEST_TEAM__ADDRESSABLES
        public IPromise CloseLastMainWindow()
        {
            if (_mainWindowsReferences.IsNullOrEmpty() || _mainWindows.IsNullOrEmpty())
                return Deferred.Resolved();

            var deferred = Deferred.GetFromPool();
            var lastIndex = _mainWindowsReferences.Count - 1;
            
            CloseWindow(_mainWindowsReferences[lastIndex]);

            return deferred;
        }

        private IPromise<GameObject> LoadWindowPrefab(AssetReference windowReference)
        {
            return AssetsLoaderService.LoadAsset<GameObject>(windowReference); 
        }
#endif

        private T CreateWindow<T>(GameObject windowPrefab, Transform windowParent, bool isOverlay) where T : Object
        {
            var windows = isOverlay ? _overlayWindows : _mainWindows;

            var foundWindowIndex = windows.FindIndex(item => item.name == windowPrefab.name);
            if (foundWindowIndex != -1)
                return windows[foundWindowIndex].GetComponent<T>();

            var window = windowParent.IsNullOrDead()
                ? Instantiate(windowPrefab)
                : Instantiate(windowPrefab, windowParent);
            
            window.name = windowPrefab.name;
            windows.Add(window);

            return window.GetComponent<T>();
        }
    }
}