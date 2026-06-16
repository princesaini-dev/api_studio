import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/export_service.dart';
import 'export_event.dart';
import 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService exportService;

  ExportBloc({required this.exportService}) : super(const ExportState()) {
    on<ExportAsJsonEvent>(_onExportJson);
    on<ExportAsTxtEvent>(_onExportTxt);
  }

  Future<void> _onExportJson(ExportAsJsonEvent event, Emitter<ExportState> emit) async {
    emit(state.copyWith(status: ExportStatus.exporting));
    try {
      final path = await exportService.exportAsJson();
      emit(state.copyWith(status: ExportStatus.success, exportedFilePath: path));
    } catch (e) {
      emit(state.copyWith(status: ExportStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onExportTxt(ExportAsTxtEvent event, Emitter<ExportState> emit) async {
    emit(state.copyWith(status: ExportStatus.exporting));
    try {
      final path = await exportService.exportAsTxt();
      emit(state.copyWith(status: ExportStatus.success, exportedFilePath: path));
    } catch (e) {
      emit(state.copyWith(status: ExportStatus.failure, errorMessage: e.toString()));
    }
  }
}
