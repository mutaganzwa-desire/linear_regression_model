import 'package:flutter/material.dart';

import 'api_service.dart';

void main() => runApp(const BreachEstimatorApp());

class BreachEstimatorApp extends StatelessWidget {
  const BreachEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breach Impact Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F4E79), useMaterial3: true),
      home: const PredictionPage(),
    );
  }
}

/// Describes one model input: a numeric field with a range, or a text field with allowed values.
class InputSpec {
  final String key; // JSON field name expected by the API
  final String label;
  final String example;
  final int? min;
  final int? max;
  final List<String>? options;

  const InputSpec.number(this.key, this.label, this.example, {required this.min, required this.max})
      : options = null;

  const InputSpec.text(this.key, this.label, this.example, {required this.options})
      : min = null,
        max = null;

  bool get isNumber => options == null;

  String get helper =>
      isNumber ? 'Whole number from $min to $max' : 'Tap to see the ${options!.length} options, or type to search';
}

/// The 12 variables the model needs, with the same types, ranges and categories as the API.
const List<InputSpec> inputs = [
  InputSpec.number('incident_year', 'Incident year', '2025', min: 2005, max: 2030),
  InputSpec.number('num_action_types', 'Number of attack action types', '1', min: 1, max: 7),
  InputSpec.number('num_data_types', 'Number of data types stolen', '2', min: 0, max: 15),
  InputSpec.text('action_type', 'Attack type', 'Hacking', options: ['Hacking', 'Malware', 'Social']),
  InputSpec.text('actor_motive', 'Attacker motive', 'Financial',
      options: ['Financial', 'Espionage', 'Ideology', 'Grudge', 'Fun', 'Fear', 'Secondary', 'Unknown']),
  InputSpec.text('actor_variety', 'Attacker type', 'Organized crime', options: [
    'Organized crime', 'Unaffiliated', 'Activist', 'Nation-state', 'State-affiliated', 'Former employee',
    'Competitor', 'Acquaintance', 'Customer', 'Terrorist', 'Unknown'
  ]),
  InputSpec.text('hacking_vector', 'Hacking entry point', 'Web application', options: [
    'Web application', 'Backdoor', 'Partner', 'VPN', 'Desktop sharing', 'Desktop sharing software',
    '3rd party desktop', 'Physical access', 'Command shell', 'Unknown'
  ]),
  InputSpec.text('data_type', 'Main data type compromised', 'Personal', options: [
    'Personal', 'Credentials', 'Medical', 'Payment', 'Bank', 'Internal', 'Classified', 'Sensitive Personal',
    'Virtual currency', 'Secrets', 'Digital certificate', 'Copyrighted', 'Unknown'
  ]),
  InputSpec.text('discovery_method', 'Who discovered the breach', 'External',
      options: ['External', 'Internal', 'Partner', 'Unknown']),
  InputSpec.text('employee_count', 'Organisation size (employees)', '1001 to 10000', options: [
    '1 to 10', '11 to 100', '101 to 1000', '1001 to 10000', '10001 to 25000', '25001 to 50000',
    '50001 to 100000', 'Over 100000', 'Small', 'Large', 'Unknown'
  ]),
  InputSpec.text('industry', 'Industry', 'Finance', options: [
    'Accommodation', 'Administrative', 'Agriculture', 'Construction', 'Education', 'Entertainment', 'Finance',
    'Healthcare', 'Information', 'Management', 'Manufacturing', 'Mining', 'Other Services',
    'Professional Services', 'Public Administration', 'Real Estate', 'Retail', 'Transportation', 'Utilities',
    'Wholesale', 'Unknown'
  ]),
  InputSpec.text('region', 'World region', 'Africa',
      options: ['Africa', 'Americas', 'Asia', 'Europe', 'Oceania', 'Unknown']),
];

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final Map<String, TextEditingController> _controllers = {
    for (final spec in inputs) spec.key: TextEditingController(),
  };
  final Map<String, FocusNode> _focusNodes = {
    for (final spec in inputs) spec.key: FocusNode(),
  };

  bool _loading = false;
  Prediction? _prediction;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(InputSpec spec) => InputDecoration(
        labelText: spec.label,
        hintText: 'e.g. ${spec.example}',
        helperText: spec.helper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        suffixIcon: spec.isNumber ? null : const Icon(Icons.arrow_drop_down),
      );

  /// Numeric inputs: a plain number text field.
  /// Category inputs: still a text field, but it shows the valid options as you type (tap one to fill it in).
  Widget _buildField(InputSpec spec) {
    if (spec.isNumber) {
      return TextField(
        controller: _controllers[spec.key],
        focusNode: _focusNodes[spec.key],
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        decoration: _decoration(spec),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: _controllers[spec.key],
        focusNode: _focusNodes[spec.key],
        optionsBuilder: (TextEditingValue value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) return spec.options!;
          return spec.options!.where((o) => o.toLowerCase().contains(query));
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          decoration: _decoration(spec),
          onSubmitted: (_) => onFieldSubmitted(),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240, maxWidth: constraints.maxWidth),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(dense: true, title: Text(option), onTap: () => onSelected(option));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Checks every field (missing, wrong type, out of range, unknown category) and builds the request body.
  /// Returns null and sets [_error] if anything is wrong.
  Map<String, dynamic>? _collectInputs() {
    final body = <String, dynamic>{};
    final problems = <String>[];

    for (final spec in inputs) {
      final raw = _controllers[spec.key]!.text.trim();
      if (raw.isEmpty) {
        problems.add('${spec.label}: value is missing.');
        continue;
      }
      if (spec.isNumber) {
        final value = int.tryParse(raw);
        if (value == null) {
          problems.add('${spec.label}: "$raw" is not a whole number.');
        } else if (value < spec.min! || value > spec.max!) {
          problems.add('${spec.label}: $value is out of range (${spec.min} to ${spec.max}).');
        } else {
          body[spec.key] = value;
        }
      } else {
        // Accept any capitalisation, but send the exact category name the API expects.
        final match = spec.options!.where((o) => o.toLowerCase() == raw.toLowerCase());
        if (match.isEmpty) {
          problems.add('${spec.label}: "$raw" is not a valid option. Pick one from the list.');
        } else {
          body[spec.key] = match.first;
        }
      }
    }

    if (problems.isNotEmpty) {
      setState(() {
        _prediction = null;
        _error = problems.join('\n');
      });
      return null;
    }
    return body;
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();
    final body = _collectInputs();
    if (body == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _prediction = null;
    });
    try {
      final result = await fetchPrediction(body);
      setState(() => _prediction = result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillExample() {
    for (final spec in inputs) {
      _controllers[spec.key]!.text = spec.example;
    }
    setState(() {
      _error = null;
      _prediction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breach Impact Estimator'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter what you know about an online attack (hacking, malware or phishing) to estimate how many '
                'records were exposed.',
                style: theme.textTheme.bodyMedium,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _fillExample, child: const Text('Fill example values')),
              ),
              for (final spec in inputs) ...[
                _buildField(spec),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 4),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _loading ? null : _predict,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Predict', style: TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 20),
              _ResultArea(loading: _loading, prediction: _prediction, error: _error),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single display area: shows the prediction, or a readable error, or a short prompt.
class _ResultArea extends StatelessWidget {
  final bool loading;
  final Prediction? prediction;
  final String? error;

  const _ResultArea({required this.loading, required this.prediction, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = error != null;

    Widget content;
    if (loading) {
      content = const Text('Predicting... (the first request can take up to a minute while the server wakes up)');
    } else if (isError) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please fix the following:',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
          const SizedBox(height: 6),
          Text(error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      );
    } else if (prediction != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated records exposed', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(_withCommas(prediction!.recordsExposed),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Severity: ${prediction!.severity}'),
          Text('log10 prediction: ${prediction!.log10Records.toStringAsFixed(3)}',
              style: theme.textTheme.bodySmall),
        ],
      );
    } else {
      content = const Text('The prediction will appear here.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? theme.colorScheme.error : theme.colorScheme.outlineVariant),
      ),
      child: content,
    );
  }

  static String _withCommas(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}