using System.Collections.Generic;
using System.Linq;
using DevAssistent.Core.Bases;
using DevAssistent.Core.Interfaces;
using DevAssistent.DataStructures.Enums;
using DevAssistent.Helpers;
using UnityEngine;

namespace DevAssistent.Services.Root
{
    public class Factory : DevAssistent.Core.Bases.Singleton<Factory>
    {
        [SerializeField] private List<GameObject> _servicePrefabs;
        [SerializeField] private List<GameObject> _managerPrefabs;

        public List<GameObject> ServicePrefabs
        {
            get => _servicePrefabs;
            set => _servicePrefabs = value;
        }

        public List<GameObject> ManagerPrefabs
        {
            get => _managerPrefabs;
            set => _managerPrefabs = value;
        }

        private List<IService> _services = new List<IService>();
        private List<IManager> _managers = new List<IManager>();
        
        #region public methods

        public static T GetService<T>() where T: IService
        {
            return Instance.InstantiateService<T>();
        }

        public static T GetManager<T>() where T : IManager
        {
            return Instance.InstantiateManager<T>(GameServices.Market);
        }
        
        public static T GetManager<T>(MarketType marketType) where T : IManager
        {
            return Instance.InstantiateManager<T>(marketType);
        }

        public static List<T> GetManagers<T>() where T : IManager
        {
            return Instance.GetManagersPrefabs<T>();
        }

        public static T CreateManager<T>(IManager manager) where T : IManager
        {
            return Instance.CreateManagerFromPrefab<T>(manager);
        }

        #endregion
        
        private T InstantiateService<T>() where T : IService
        {
            var aliveService = _services.Find(item => !item.IsNullOrDead() && item is T);
            if (!aliveService.IsNullOrDead() && !aliveService.GetGameObject().IsNullOrDead())
                return aliveService.GetGameObject().GetComponent<T>();
            
            var prefab = GetServicePrefab<T>();
            if (prefab.IsNullOrDead())
                return default;

            var service = Instantiate(prefab, transform).GetComponent<T>();
            service.GetGameObject().name = prefab.name;
            _services.Add(service);
            
            return service;
        }

        private GameObject GetServicePrefab<T>() where T : IService
        {
            if (_servicePrefabs.IsNullOrEmpty())
                return default;

            return _servicePrefabs.Find(prefab => !prefab.GetComponent<T>().IsNullOrDead());
        }
        
        private T InstantiateManager<T>(MarketType marketType) where T : IManager
        {
            var market = Application.isEditor ? MarketType.Editor : marketType;
            var aliveManager = _managers.Find(item 
                => !item.IsNullOrDead() 
                   && !item.GetGameObject().IsNullOrDead() 
                   && item is T);
            
            if (!aliveManager.IsNullOrDead())
                return aliveManager.GetGameObject().GetComponent<T>();

            var prefab = GetManagerPrefab<T>(market);
            if (prefab.IsNullOrDead())
                return default;

            var manager = Instantiate(prefab, transform).GetComponent<T>();
            manager.GetGameObject().name = prefab.name;
            _managers.Add(manager);
            
            return manager;
        }

        private GameObject GetManagerPrefab<T>(MarketType market) where T : IManager
        {
            if (_managerPrefabs.IsNullOrDead())
                return default;
            
            return FindManagerPrefab<T>(market) ?? FindManagerPrefab<T>(MarketType.Editor);
        }

        private GameObject FindManagerPrefab<T>(MarketType market) where T : IManager
        {
            return (from prefab in _managerPrefabs
                let manager = prefab.GetComponent<T>()
                where !manager.IsNullOrDead() && manager.IsManagerForMarket(market)
                select prefab)
                .ToList()
                .Find(prefab => prefab.GetComponent<T>().IsManagerForMarket(market));
        }

        private List<T> GetManagersPrefabs<T>() where T : IManager
        {
            return _managerPrefabs.Select(manager => manager.GetComponent<T>())
                .Where(t => !t.IsNullOrDead())
                .ToList();
        }

        private T CreateManagerFromPrefab<T>(IManager managerPrefab) where T : IManager
        {
            var aliveManager = _managers
                .Find(item => !item.IsNullOrDead() 
                              && !item.GetGameObject().IsNullOrDead() 
                              && item.GetGameObject().name == managerPrefab.GetGameObject().name);
            
            if (!aliveManager.IsNullOrDead())
                return aliveManager.GetGameObject().GetComponent<T>();

            if (managerPrefab.IsNullOrDead()
                || !managerPrefab.IsNullOrDead()
                && managerPrefab.GetGameObject().IsNullOrDead())
            {
                return default;
            }

            var manager = Instantiate(managerPrefab.GetGameObject(), transform).GetComponent<T>();
            manager.GetGameObject().name = managerPrefab.GetGameObject().name;
            _managers.Add(manager);
            
            return manager;
        }
    }
}