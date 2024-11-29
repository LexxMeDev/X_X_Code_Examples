using System;
using DevAssistent.Core.Bases;
using DevAssistent.Core.Promises;
using DevAssistent.Core.Services.CallbacksService.Bases;
using UnityEngine;

namespace DevAssistent.Core.Services.CallbacksService
{
    public class CallbackService : DevAssistent.Core.Bases.Singleton<CallbackService>
    {
        [SerializeField] private GameObject _callbackPrefab;

        private static GameObject CallbackPrefab => Instance._callbackPrefab;

        public static BaseCallback RegisterCallback(Deferred<string> result = null)
        {
            Instance = Instance == null ? GetNewCallbackServices() : Instance;
            var callbackHandler = Instantiate(CallbackPrefab, Instance.transform).GetComponent<BaseCallback>();
            callbackHandler.name = $"request_handler_{Guid.NewGuid().ToString()}";
            callbackHandler.Setup(result);
            return callbackHandler;
        }
        
        private static CallbackService GetNewCallbackServices()
        {
            var prefab = Resources.Load<CallbackService>(nameof(CallbackService));
            return Instantiate(prefab).GetComponent<CallbackService>();
        }
    }
}