import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'selection_state.dart';

@injectable
class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionState.initial());

  void selectProblem(Problem? problem) {
    emit(
      state.copyWith(
        selectedProblem: problem,
        isViewingDetail: problem != null,
      ),
    );
  }

  void setCurrentList(String listName) {
    emit(state.copyWith(currentList: listName));
  }

  void exitDetail() {
    emit(state.copyWith(isViewingDetail: false));
  }
}
