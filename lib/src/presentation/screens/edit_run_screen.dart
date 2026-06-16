import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import '../blocs/edit_run/edit_run_bloc.dart';
import '../blocs/edit_run/edit_run_event.dart';
import '../blocs/edit_run/edit_run_state.dart';

class EditRunScreen extends StatelessWidget {
  final ApiLogEntity log;

  const EditRunScreen({super.key, required this.log});

  static Route<void> route({required ApiLogEntity log}) {
    return MaterialPageRoute(builder: (_) => EditRunScreen(log: log));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiService.createEditRunBloc()..add(InitEditRunEvent(log)),
      child: const _EditRunView(),
    );
  }
}

class _EditRunView extends StatelessWidget {
  const _EditRunView();

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return BlocConsumer<EditRunBloc, EditRunState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == EditRunStatus.success && state.resultLog != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Request completed — ${state.resultLog!.statusCode ?? 'No status'}',
              ),
              backgroundColor: state.resultLog!.isSuccess
                  ? theme.successColor
                  : theme.errorColor,
            ),
          );
          Navigator.of(context).pop();
        }
        if (state.status == EditRunStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Request failed'),
              backgroundColor: theme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            backgroundColor: theme.surfaceColor,
            elevation: 0,
            title: Text('Edit & Run',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: theme.textPrimaryColor)),
            actions: [
              if (state.status == EditRunStatus.running)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('RUN'),
                    onPressed: () => context
                        .read<EditRunBloc>()
                        .add(const RunRequestEvent()),
                  ),
                ),
            ],
          ),
          body: const _EditRunForm(),
        );
      },
    );
  }
}

class _EditRunForm extends StatefulWidget {
  const _EditRunForm();

  @override
  State<_EditRunForm> createState() => _EditRunFormState();
}

class _EditRunFormState extends State<_EditRunForm> {
  late final TextEditingController _urlController;
  late final TextEditingController _bodyController;
  final Map<TextEditingController, TextEditingController> _headerControllers =
      {};
  final Map<TextEditingController, TextEditingController> _paramControllers =
      {};
  bool _initialized = false;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    for (final c in _headerControllers.keys) {
      c.dispose();
    }
    for (final c in _headerControllers.values) {
      c.dispose();
    }
    for (final c in _paramControllers.keys) {
      c.dispose();
    }
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(EditRunState state) {
    if (_initialized) return;
    // Wait until the bloc has processed InitEditRunEvent (url will be non-empty)
    if (state.originalLog == null) return;
    _initialized = true;
    _urlController = TextEditingController(text: state.url);
    _bodyController = TextEditingController(text: state.body ?? '');
    state.headers.forEach((k, v) {
      _headerControllers[TextEditingController(text: k)] =
          TextEditingController(text: v.toString());
    });
    state.queryParams.forEach((k, v) {
      _paramControllers[TextEditingController(text: k)] =
          TextEditingController(text: v.toString());
    });
  }

  void _syncHeaders(BuildContext context) {
    final headers = <String, dynamic>{};
    _headerControllers.forEach((k, v) {
      if (k.text.isNotEmpty) headers[k.text] = v.text;
    });
    context.read<EditRunBloc>().add(UpdateHeadersEvent(headers));
  }

  void _syncParams(BuildContext context) {
    final params = <String, dynamic>{};
    _paramControllers.forEach((k, v) {
      if (k.text.isNotEmpty) params[k.text] = v.text;
    });
    context.read<EditRunBloc>().add(UpdateQueryParamsEvent(params));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return BlocBuilder<EditRunBloc, EditRunState>(
      buildWhen: (p, c) => !_initialized || p.status != c.status,
      builder: (context, state) {
        _initControllers(state);
        if (!_initialized) {
          return Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(Dimensions.lg),
          children: [
            _SectionLabel('Method', theme: theme),
            _MethodSelector(
              selected: state.method,
              onChanged: (m) =>
                  context.read<EditRunBloc>().add(UpdateMethodEvent(m)),
              theme: theme,
            ),
            const SizedBox(height: Dimensions.lg),
            _SectionLabel('URL', theme: theme),
            _StyledTextField(
              controller: _urlController,
              hintText: 'https://api.example.com/endpoint',
              theme: theme,
              onChanged: (v) =>
                  context.read<EditRunBloc>().add(UpdateUrlEvent(v)),
            ),
            const SizedBox(height: Dimensions.lg),
            _KVSection(
              title: 'Headers',
              controllers: _headerControllers,
              theme: theme,
              onChanged: () => _syncHeaders(context),
              onAdd: () {
                setState(() {
                  _headerControllers[TextEditingController()] =
                      TextEditingController();
                });
              },
            ),
            const SizedBox(height: Dimensions.lg),
            _KVSection(
              title: 'Query Params',
              controllers: _paramControllers,
              theme: theme,
              onChanged: () => _syncParams(context),
              onAdd: () {
                setState(() {
                  _paramControllers[TextEditingController()] =
                      TextEditingController();
                });
              },
            ),
            const SizedBox(height: Dimensions.lg),
            _SectionLabel('Body (JSON)', theme: theme),
            _StyledTextField(
              controller: _bodyController,
              hintText: '{"key": "value"}',
              theme: theme,
              maxLines: 8,
              onChanged: (v) =>
                  context.read<EditRunBloc>().add(UpdateBodyEvent(v)),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _MethodSelector extends StatefulWidget {
  final HttpMethod selected;
  final ValueChanged<HttpMethod> onChanged;
  final dynamic theme;

  const _MethodSelector(
      {required this.selected, required this.onChanged, required this.theme});

  @override
  State<_MethodSelector> createState() => _MethodSelectorState();
}

class _MethodSelectorState extends State<_MethodSelector> {
  late HttpMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  void didUpdateWidget(_MethodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HttpMethod.values.map((m) {
          final isSelected = m == _selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selected = m);
                widget.onChanged(m);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.theme.primaryColor
                      : widget.theme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? widget.theme.primaryColor
                        : widget.theme.borderColor,
                  ),
                ),
                child: Text(
                  m.name.toUpperCase(),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected
                        ? Colors.white
                        : widget.theme.textPrimaryColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KVSection extends StatefulWidget {
  final String title;
  final Map<TextEditingController, TextEditingController> controllers;
  final dynamic theme;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  const _KVSection({
    required this.title,
    required this.controllers,
    required this.theme,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  State<_KVSection> createState() => _KVSectionState();
}

class _KVSectionState extends State<_KVSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel(widget.title, theme: widget.theme),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: widget.onAdd,
            ),
          ],
        ),
        ...widget.controllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _StyledTextField(
                    controller: entry.key,
                    hintText: 'Key',
                    theme: widget.theme,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StyledTextField(
                    controller: entry.value,
                    hintText: 'Value',
                    theme: widget.theme,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      size: 18, color: widget.theme.textSecondaryColor),
                  onPressed: () {
                    setState(() {
                      widget.controllers.remove(entry.key);
                    });
                    widget.onChanged();
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final dynamic theme;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.theme,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: theme.textPrimaryColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: theme.textSecondaryColor),
        filled: true,
        fillColor: theme.surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final dynamic theme;
  const _SectionLabel(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: AppTextStyles.titleMedium
              .copyWith(color: theme.textSecondaryColor)),
    );
  }
}
