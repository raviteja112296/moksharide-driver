// class DriverHomeController {
//   final DriverStatusService statusService;
//   final DriverRideRepository rideRepo;
//   final FCMService fcmService;

//   StreamSubscription? rideSub;

//   bool isOnline = true;
//   bool isDialogOpen = false;

//   DriverHomeController({
//     required this.statusService,
//     required this.rideRepo,
//     required this.fcmService,
//   });

//   Future<void> init({required bool forceOnline}) async {
//     await fcmService.initFCM();
//     await fcmService.saveFCMTokenToFirestore();

//     if (forceOnline) {
//       await setOnline(true);
//     }
//   }

//   Future<void> setOnline(bool value) async {
//     isOnline = value;
//     await statusService.setOnlineStatus(value);

//     if (value) {
//       startListeningRides();
//     } else {
//       stopListeningRides();
//     }
//   }

//   void startListeningRides() {
//     rideSub?.cancel();
//     rideSub = rideRepo.getPendingRides().listen((rides) {
//       if (rides.isEmpty || isDialogOpen) return;
//       isDialogOpen = true;
//     });
//   }

//   void stopListeningRides() {
//     rideSub?.cancel();
//   }

//   void dispose() {
//     rideSub?.cancel();
//   }
// }
