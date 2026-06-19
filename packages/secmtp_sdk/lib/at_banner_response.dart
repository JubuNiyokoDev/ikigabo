
import  'package:secmtp_sdk/at_base_response.dart';


/*Banner ad status */
enum BannerStatus {
  bannerAdFailToLoadAD,
  bannerAdDidFinishLoading,
  bannerAdAutoRefreshSucceed,
  bannerAdDidClick,
  bannerAdDidDeepLink,
  bannerAdDidShowSucceed,
  bannerAdTapCloseButton,
  bannerAdAutoRefreshFail,

  bannerAdDidMultipleLoaded,

  bannerAdDidAdSourceBiddingAttempt,
  bannerAdDidAdSourceBiddingFilled,
  bannerAdDidAdSourceBiddingFail,
  bannerAdDidAdSourceAttempt,
  bannerAdDidAdSourceLoadFilled,
  bannerAdDidAdSourceLoadFail,

  bannerAdUnknown
}

class ATBannerResponse extends BaseResponse{
  final BannerStatus bannerStatus;
  final Map extraMap;

  ATBannerResponse(this.bannerStatus,this.extraMap,String errStr,String placementID,bool isDeeplinkSuccess):
        super(errStr,placementID,isDeeplinkSuccess);

  factory ATBannerResponse.withMap(Map map){
    var tempRewardStatus;
    var requestMessage = map['requestMessage'];

    var placementID = map['placementID'];

    var adStatus = map['callbackName'];

    var tempExtraMap;

    var isDeeplinkSuccess = false;
    if (map.containsKey('isDeeplinkSuccess')){
      isDeeplinkSuccess =  map['isDeeplinkSuccess'];
    }

    if (map.containsKey('extraDic')){
      tempExtraMap =  map['extraDic'];
    }else{
      tempExtraMap =  {'message': 'No additional information'};
    }

    if (adStatus == 'bannerAdFailToLoadAD'){
      tempRewardStatus = BannerStatus.bannerAdFailToLoadAD;
    }
    else if(adStatus == 'bannerAdDidFinishLoading'){
      tempRewardStatus = BannerStatus.bannerAdDidFinishLoading;
    }
    else if(adStatus == 'bannerAdAutoRefreshSucceed'){
      tempRewardStatus = BannerStatus.bannerAdAutoRefreshSucceed;
    }
    else if(adStatus == 'bannerAdDidClick'){
      tempRewardStatus = BannerStatus.bannerAdDidClick;
    }
    else if(adStatus == 'bannerAdDidDeepLink'){
      tempRewardStatus = BannerStatus.bannerAdDidDeepLink;
    }

    else if(adStatus == 'bannerAdDidMultipleLoaded'){
      tempRewardStatus = BannerStatus.bannerAdDidMultipleLoaded;
    }
    else if(adStatus == 'bannerAdDidAdSourceBiddingAttempt'){
      tempRewardStatus = BannerStatus.bannerAdDidAdSourceBiddingAttempt;
    }
    else if(adStatus == 'bannerAdDidAdSourceBiddingFilled'){
      tempRewardStatus = BannerStatus.bannerAdDidAdSourceBiddingFilled;
    }
    else if(adStatus == 'bannerAdDidAdSourceBiddingFail'){
      tempRewardStatus = BannerStatus.bannerAdDidAdSourceBiddingFail;
    }
    else if(adStatus == 'bannerAdDidAdSourceAttempt'){
      tempRewardStatus = BannerStatus.bannerAdDidAdSourceAttempt;
    }
    else if(adStatus == 'bannerAdDidAdSourceLoadFilled'){
      tempRewardStatus = BannerStatus.bannerAdDidAdSourceLoadFilled;
    }
    else if(adStatus == 'bannerAdDidAdSourceLoadFail'){
      tempRewardStatus = BannerStatus.bannerAdDidAdSourceLoadFail;
    }

    else if(adStatus == 'bannerAdDidShowSucceed'){
      tempRewardStatus = BannerStatus.bannerAdDidShowSucceed;
    }
    else if(adStatus == 'bannerAdTapCloseButton'){
      tempRewardStatus = BannerStatus.bannerAdTapCloseButton;
    }
    else if(adStatus == 'bannerAdAutoRefreshFail'){
      tempRewardStatus = BannerStatus.bannerAdAutoRefreshFail;
    }
    else{
      tempRewardStatus = BannerStatus.bannerAdUnknown;
    }

    return ATBannerResponse(tempRewardStatus,tempExtraMap,requestMessage,placementID,isDeeplinkSuccess);
  }

}


