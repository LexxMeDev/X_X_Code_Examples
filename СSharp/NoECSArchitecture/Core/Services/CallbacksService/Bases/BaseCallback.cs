using DevAssistent.Core.Bases;
using DevAssistent.Core.Promises;
using DevAssistent.Helpers;
using DevAssistent.Services.MainThread;

namespace DevAssistent.Core.Services.CallbacksService.Bases
{
    public class BaseCallback : BaseMonoBehaviour
    {
        public Deferred<string> CallbackDeferred => _callbackDeferred;
        
        public string CallbackId => name;
        public string SuccessMethodName => nameof(SuccessRequestHandler);
        public string FailedMethodName => nameof(FailedRequestHandler);

        private Deferred<string> _callbackDeferred;
        
        public void Setup(Deferred<string> result = null)
        {
            _callbackDeferred = result;
        }

        public void SuccessRequestHandler(string result)
        {
            MainThreadService.Enqueue(() =>
            {
                if (_callbackDeferred.IsNullOrDead())
                    return;
                
                if (result.IsNullOrEmpty())
                {
                    _callbackDeferred.Resolve("");
                    return;   
                }
                
                _callbackDeferred.Resolve(result);
            });
        }
        
        public void FailedRequestHandler(string err)
        {
            MainThreadService.Enqueue(() =>
            {
                if (_callbackDeferred.IsNullOrDead())
                    return;

                if (err.IsNullOrEmpty())
                {
                    _callbackDeferred.Reject("");
                    return;
                }
                
                _callbackDeferred.Reject(err);
            });
        }

        public void Delete()
        {
            if (gameObject.IsNullOrDead())
                return;
            Destroy(gameObject);
        }
    }
}