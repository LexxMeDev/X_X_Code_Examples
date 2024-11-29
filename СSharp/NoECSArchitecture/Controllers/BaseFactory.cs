using System.Collections.Generic;
using System.Linq;
using DevAssistent.Helpers;
using SomeProject.Core.Bases;
using SomeProject.Core.Interfaces;
using UnityEngine;

namespace SomeProject.Controllers
{
    public class BaseFactory : BaseMonoBehaviour
    {
        private static BaseFactory _instance;
        public static BaseFactory Instance => _instance;

        private void Awake() => _instance = this;
        
        [SerializeField] private List<GameObject> _managersPrefabs;

        private List<IManager> _managers = new List<IManager>();

        public T GetManager<T>() where T : IManager
        {
            var manager = _managers.FirstOrDefault(item => item is T);
            if (manager != null) 
                return (T) manager;
            
            var managerPrefab = GetManagerPrefab<T>();
            if (managerPrefab.IsNullOrDead())
            {
                return default;
            }

            var managerGameObject = Instantiate(managerPrefab, transform);
            managerGameObject.name = managerPrefab.name;
            manager = managerGameObject.GetComponent<T>();
            _managers.Add(manager);

            return (T) manager;
        }

        private GameObject GetManagerPrefab<T>() where T : IManager
        {
            if (_managersPrefabs == null)
                return default;

            foreach (var prefab in _managersPrefabs)
            {
                if (prefab == null) 
                    continue;
                
                var manager = prefab.GetComponent<T>();
                if (manager != null)
                    return prefab;
            }

            return default;
        }

#if UNITY_EDITOR
        public void OnValidate()
        {
            if (_managersPrefabs == null)
                return;
            
            for (var i = 0; i < _managersPrefabs.Count; i++)
            {
                var managerObject = _managersPrefabs[i];
                if (managerObject != null && managerObject.GetComponent<IManager>() == null)
                    _managersPrefabs[i] = null;
            }
        }
#endif
    }
}