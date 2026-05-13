// This cubit file stores the selected index for the app's main bottom navigation.
// Home listens to this simple integer state to switch between tab pages.
import 'package:flutter_bloc/flutter_bloc.dart';

// HomeNavCubit emits the active tab index whenever the user changes sections.
class HomeNavCubit extends Cubit<int> {
  HomeNavCubit() : super(0);

  // This method updates the selected tab index used by the home page.
  void selectTab(int index) => emit(index);
}
