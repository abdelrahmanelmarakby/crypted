import 'dart:developer';

import 'package:crypted/core/services/get_storage_helper.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../services/network_service.dart/dio_network_service.dart';

const String dummyImage = "https://picsum.photos/800";
const String emptyImage = "https://assets2.lottiefiles.com/private_files/lf30_e3pteeho.json";
const String userImage =
    "https://firebasestorage.googleapis.com/v0/b/elkady-dataflow.appspot.com/o/profile.png?alt=media&token=ce956826-60d0-4274-98c3-39f32e6ff5fd&_gl=1*1f9d2nj*_ga*MTA5MjI0NDU4LjE2Nzk5MDg4MzY.*_ga_CW55HF8NVT*MTY5NjUwMzEwOS4xNDUuMS4xNjk2NTAzMzQ0LjUxLjAuMA..";
final NetworkService networkService = NetworkService(
  baseUrl: APIKeys.baseUrl,
  httpHeaders: {
    'Accept': 'application/json',
    "Accept-Language": CacheHelper.getLocale,
  },
);
String appDateFormat(DateTime date) {
  String pattern = 'yyyy-MM-dd';
  var format = DateFormat(pattern, "en");
  var dateString = format.format(date);
  return dateString;
}

String appTimeFormat(DateTime time) {
  String pattern = 'HH:mm';
  var format = DateFormat(pattern, "en");
  var timeString = format.format(time);
  return timeString;
}

String timeUntil(String val) {
  DateTime date = DateTime.tryParse(val) ?? DateTime.now();
  return timeago.format(date, allowFromNow: true, locale: CacheHelper.getLocale);
}

extension Filter<T> on Stream<List<T>> {
  Stream<List<T>> filter(bool Function(T) where) => map(
        (items) => items.where(where).toList(),
      );
}

extension CustomList<T> on List<T> {
  List<T> asReversed(bool isReverse) {
    return isReverse ? reversed.toList() : this;
  }

  T? elementAtOrNull(int index) {
    try {
      return this[index];
    } catch (_) {}
    return null;
  }
}

const int pageLimit = 10;

class APIKeys {
  static String baseUrl = 'http://91.108.102.81:9099/';
  static const String pusherAppId = "";
  static const String pusherKey = "";
  static const String pusherSecret = "";
  static const String pusherCluster = "";
  static const String googleMapsKey = "AIzaSyB8hNYecmEEalWQivvkNyBz-Cxtyvg3Kng";
  static const String apiPassword =
      "\$2y\$12\$lKLPBP1GlcywPnqPZceE4OcTWQNMrTgoshgoz91DrvvuTFMGiUI32";
  static const String sentryKey = "";
  static const String paymentKeyTest =
      "rLtt6JWvbUHDDhsZnfpAhpYk4dxYDQkbcPTyGaKp2TYqQgG7FGZ5Th_WD53Oq8Ebz6A53njUoo1w3pjU1D4vs_ZMqFiz_j0urb_BH9Oq9VZoKFoJEDAbRZepGcQanImyYrry7Kt6MnMdgfG5jn4HngWoRdKduNNyP4kzcp3mRv7x00ahkm9LAK7ZRieg7k1PDAnBIOG3EyVSJ5kK4WLMvYr7sCwHbHcu4A5WwelxYK0GMJy37bNAarSJDFQsJ2ZvJjvMDmfWwDVFEVe_5tOomfVNt6bOg9mexbGjMrnHBnKnZR1vQbBtQieDlQepzTZMuQrSuKn-t5XZM7V6fCW7oP-uXGX-sMOajeX65JOf6XVpk29DP6ro8WTAflCDANC193yof8-f5_EYY-3hXhJj7RBXmizDpneEQDSaSz5sFk0sV5qPcARJ9zGG73vuGFyenjPPmtDtXtpx35A-BVcOSBYVIWe9kndG3nclfefjKEuZ3m4jL9Gg1h2JBvmXSMYiZtp9MR5I6pvbvylU_PP5xJFSjVTIz7IQSjcVGO41npnwIxRXNRxFOdIUHn0tjQ-7LwvEcTXyPsHXcMD8WtgBh-wxR8aKX7WPSsT1O8d8reb2aR7K3rkV3K82K_0OgawImEpwSvp9MNKynEAJQS6ZHe_J_l77652xwPNxMRTMASk1ZsJL";
  static const String paymentKeyLive = "";
  //-------------------------------------auth-----------------------------------//
  static const String login = "api/users/auth/login";
  static const String register = "api/users/auth/signup";
  static const String verifyPhone = "api/users/verify-otp";
  static const String verifyForgotPasswordOtp = "api/verifyForgotPasswordOtp";
  static const String forgetPassword = "api/users/forgot-password";
  static const String resetPassword = "api/users/reset-password";
  static const String getUserData = "";
  static const String updateUser = "api/users/auth/";
  static const String logout = "api/users/auth/logout";
  static const String deleteUser = "";
  static const String changePassword = "";
  //-------------------------------------home-----------------------------------//
  static const String getHome = "api/home";
  static const String getAdsByCategoriesType = "api/ads/category/";
  static const String getAllPanners = "api/panners";
  static const String getAllCategories = "api/department";
  //-------------------------------------ads-----------------------------------//
  static const String ads = "api/ads";
  static const String adCommentsByAdId = "api/comments/ad/";
  static const String sellerAdsAndInfoBySellerId = 'api/ads/user';
  static const String getAdTypes = "api/categories";
  static const String getHorseClass = 'api/horse-classes';
  static const String nonPromotedAds = 'api/promotions/ads/not-promoted';
  static const String nonStabilizedAds = 'api/user/non-stabilized-ads';
  static const String userAds = 'api/ads/user/';
  static const String markAdAsSold = 'api/ads/';
  static const String republishAd = 'api/republish-ad';
  static const String adRate = 'api/reviews';
  static const String reportAd = 'api/report/ad';
  //-------------------------------------comments-----------------------------------//
  static const String addComment = "api/comments";
  static const String commentsByUserId = 'api/comments/user/';
  //-------------------------------------store-----------------------------------//
  static const String getAllStores = "api/stores";
  static const String getStoreById = "api/store/";
  static const String createStore = "api/store";
  static const String getUserStores = "/api/stores/user";
  static const String verifyStore = "api/store/verification";
  static String rateStore = 'api/stores/${CacheHelper.getStoreId}/reviews';

  static const String getHorseAdvertisements = "api/advertisement";
  static const String getSuppliesAdvertisements = "supplies";

  static const String getAllLocations = "api/locations/city/1";
  //-------------------------------------profile-----------------------------------//
  static const String profile = "api/users/profile";
  static const String fav = "api/favourites";
  static const String promotion = "api/promotions";
  static const String stabilization = 'api/create-stabilization';
  static const String getPromotionPrice = "/api/promotion-price";
  static const String getStabilizationPrice = 'api/calculate-stabilization-costs';
  static const String payment = 'api/get-payment-status';
  static const String getMyPayment = "api/get-payment-history";
  static const String commissionPay = "api/commissions/pay";
  static const String points = 'api/wallet/get-refund-points/';
  static const String selectPoints = 'api/wallet/select-promotion-package';
  //-------------------------------------static profile-----------------------------------//
  static const String getFaq = "api/faqs";
  static const String getTerms = "api/terms-conditions";
  static const String getPrivacy = "api/privacy-policy";
  static const String getAbout = "api/about-us";
  static const String getUserChatRooms = "api/chat/chat-rooms/";
  static const String deleteChatRoom = "api/chat/";

  static const String getChatMessages = "api/chat/messages/";
  static const String sendMessage = "api/send";
  static const String reportChat = "api/report/chat/";
  static const String createChat = "api/chat/initiate";
}

void openUrl(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    log("Could not launch url");
  }
}
