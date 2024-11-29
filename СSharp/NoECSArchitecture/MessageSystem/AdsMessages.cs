using DevAssistent.Controllers.Ads;
using DevAssistent.Core.Services.MessageServices.Bases;
using DevAssistent.DataStructures.Transfer.Models.Ads;

namespace DevAssistent.MessageSystem
{
    public static partial class Messages
    {
        public static class Ads
        {
            public static class RewardVideo
            {
                public sealed class Showed : BaseMessage<Showed>
                {
                }

                public sealed class Rewarded : BaseMessage<Rewarded>
                {
                }

                public sealed class Closed : BaseMessage<Closed>
                {
                }
                
                public sealed class Failed : BaseMessage<Failed, string>
                {
                }
            }

            public static class Interstitial
            {
                public sealed class Showed : BaseMessage<Showed, AdsBlock>
                {
                }
                
                public sealed class Closed : BaseMessage<Closed>
                {
                }
                
                public sealed class Hided : BaseMessage<Hided, AdsBlock>
                {
                }
            }

            public static class Banner
            {
                public sealed class Showed : BaseMessage<Showed, AdsBlock>
                {
                }
                public sealed class Hided : BaseMessage<Hided, AdsBlock>
                {
                }

                public sealed class FailedShow : BaseMessage<FailedShow, (AdsBlock, string)>
                {
                }

                public sealed class Activated : BaseMessage<Activated, SPYandexBannerController>
                {
                }

                public sealed class Deactivated : BaseMessage<Deactivated, SPYandexBannerController>
                {
                }
            }
        }
    }
}