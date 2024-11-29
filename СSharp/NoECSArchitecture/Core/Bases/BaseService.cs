using DevAssistent.Core.Interfaces;
using DevAssistent.Core.Promises;
using UnityEngine;

namespace DevAssistent.Core.Bases
{
    public class BaseService : BaseMonoBehaviour, IService
    {
        public GameObject GetGameObject()
        {
            return gameObject;
        }

        public virtual IPromise Initialize()
        {
            return Deferred.Resolved();
        }
    }
}