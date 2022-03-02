import 'package:cli_dialog/cli_dialog.dart';
import 'package:dcli/dcli.dart';

import '../argument-parser.dart';
import '../util/console-helper.dart';

import '../wp-cli/wp-cli-interface.dart';
import 'config.dart';

final Map<OperationType, String> OperationSelectionOptions = const {
  OperationType.database: 'Wordpress database only',
  OperationType.userdata: 'Userdata directories only',
  OperationType.all: 'Both database and userdata',
};

enum ProjectPathPreset {
  cwd,
  userHome,
  custom,
}

final Map<ProjectPathPreset, String> ProjectPathPresetOptions = const {
  ProjectPathPreset.cwd: 'The current working directory (".")',
  ProjectPathPreset.userHome: 'The backup user\'s \$HOME',
  ProjectPathPreset.custom: 'A custom path',
};

final Map WpCliPresetOptions = const {
  WpCliType.bundled: 'Use the bundled PHAR archive of WP-CLI (recommended)',
  WpCliType.path: 'Use the executable PHAR named "wp" on the \$PATH',
  WpCliType.directory:
      'Use the "wp" PHAR next to the wp-backup binary (recommended when using wp-backup-pack)',
  WpCliType.custom: 'Use a custom path to WP-CLI',
};

class Wizard {
  final Config config;

  late CLI_Dialog dialog;

  late Map previousAnswers;

  Wizard(this.config, WpCli wpCli) {
    dialog = CLI_Dialog();
    dialog.order = [];

    _maybeAskCommand();
    _maybeAskOperation();
    _maybeAskProjectDirectoryPreset();
    _maybeAskVerbosity();
    _maybeAskWpBinaryType(wpCli);
  }

  Config run() {
    Map answers = dialog.ask();
    _applyAnswersToConfiguration(answers);

    if (_needsClarification(answers)) {
      _askDetails(answers);
    }

    return this.config;
  }

  void _askDetails(Map previousAnswers) {
    dialog = CLI_Dialog();
    dialog.order = [];
    this.previousAnswers = previousAnswers;

    _maybeClarifyCustomProjectDirectory();
    _maybeClarifyCustomWpBinary();

    Map answers = dialog.ask();

    _applyClarificationToConfiguration(answers);
  }

  void _applyAnswersToConfiguration(Map answers) {
    if (config.command == null) {
      config.command = answers['command'];
    }

    if (!config.hasOperation()) {
      var operationAnswer =
          _getAnswerByOption(answers, ConfigurationOption.operation);
      var selectedOption = OperationSelectionOptions.entries
          .firstWhere((element) => element.value == operationAnswer);
      this.config.operation = selectedOption.key;
    }

    if (!this.config.verbose) {
      this.config.verbose =
          _getFlagByOption(answers, ConfigurationOption.verbose);
    }

    if (config.wpBinary == null) {
      var wpBinaryType = _getAnswerByOption(answers, ConfigurationOption.wpBinaryType);
      if (wpBinaryType == WpCliPresetOptions[WpCliType.bundled]) {
        config.wpBinaryType = WpCliType.bundled;
      } else if (wpBinaryType == WpCliPresetOptions[WpCliType.directory]) {
        config.wpBinaryType = WpCliType.directory;
      } else if (wpBinaryType == WpCliPresetOptions[WpCliType.path]) {
        config.wpBinaryType = WpCliType.path;
      } else if (wpBinaryType == WpCliPresetOptions[WpCliType.custom]) {
        config.wpBinaryType = WpCliType.custom;
      }
    }

    if (config.projectDirectory == null) {
      var selection = answers['projectPathPreset'];

      if (selection == ProjectPathPresetOptions[ProjectPathPreset.cwd]) {
        config.projectDirectory = 'realpath .'.firstLine;
      } else if (selection ==
          ProjectPathPresetOptions[ProjectPathPreset.userHome]) {
        config.projectDirectory =
            ConsoleHelper().userdoFirstLine('realpath \$HOME');
      }
    }
  }

  void _applyClarificationToConfiguration(Map answers) {
    String? previousAnswer = _getAnswerByOption(previousAnswers, ConfigurationOption.wpBinaryType);
    if (previousAnswer == WpCliPresetOptions[WpCliType.custom]) {
      config.wpBinary = answers[_getKey(ConfigurationOption.wpBinary)];
    }

    if (previousAnswers['projectPathPreset'] ==
        ProjectPathPresetOptions[ProjectPathPreset.custom]) {
      config.projectDirectory =
          answers[_getKey(ConfigurationOption.projectDirectory)];
    }
  }

  _getAnswerByOption(answers, option) {
    return answers[_getKey(option)];
  }

  bool _getFlagByOption(answers, option) {
    var answerGiven = answers[_getKey(option)];
    return answerGiven != null ? answerGiven : false;
  }

  String? _getKey(ConfigurationOption option) {
    return Config.getParameter(option);
  }

  void _maybeAskCommand() {
    if (config.command == null) {
      String key = 'command';

      _makeListQuestion(key, 'Select what it is you would like to do:', [Commands.backup, Commands.restore]);
      dialog.order!.add(key);
    }
  }

  /**
   * Ask the user which backup operation to perform if it's not provided yet.
   */
  void _maybeAskOperation() {
    String key = _getKey(ConfigurationOption.operation)!;

    if (!config.hasOperation()) {
      _makeListQuestion(key, 'What is it you would like to back up?', <String>[
        OperationSelectionOptions[OperationType.all]!,
        OperationSelectionOptions[OperationType.database]!,
        OperationSelectionOptions[OperationType.userdata]!,
      ]);
    } else {
      _makeMessage(key, 'Operation ${config.operation} selected.');
    }

    dialog.order!.add(key);
  }

  /**
   * Ask the user whether to use the CWD, their $HOME or a custom directory,
   * unless one has been provided.
   */
  void _maybeAskProjectDirectoryPreset() {
    if (config.projectDirectory == null) {
      String key = 'projectPathPreset';

      _makeListQuestion(key, 'Where is your Wordpress deployment located?', [
        ProjectPathPresetOptions[ProjectPathPreset.cwd]!,
        ProjectPathPresetOptions[ProjectPathPreset.userHome]!,
        ProjectPathPresetOptions[ProjectPathPreset.custom]!,
      ]);

      dialog.order!.add(key);
    }
  }

  void _maybeAskVerbosity() {
    if (!config.verbose) {
      String key = _getKey(ConfigurationOption.verbose)!;
      _makeQuestion(key, 'Would you like to enable verbose output?', true);
      dialog.order!.add(key);
    }
  }

  void _maybeAskWpBinaryType(WpCli wpCli) {
    if (config.wpBinaryType == null) {
      String key = _getKey(ConfigurationOption.wpBinaryType)!;
      List<String> options = [];
      if (wpCli.isBundled) {
        options.add(WpCliPresetOptions[WpCliType.bundled]);
      }

      options.add(WpCliPresetOptions[WpCliType.path]);
      options.add(WpCliPresetOptions[WpCliType.directory]);
      options.add(WpCliPresetOptions[WpCliType.custom]);

      _makeListQuestion(
          key, 'Which WP-CLI binary would you like to use?', options);

      dialog.order!.add(key);
    }
  }

  void _maybeClarifyCustomProjectDirectory() {
    if (previousAnswers['projectPathPreset'] ==
        ProjectPathPresetOptions[ProjectPathPreset.custom]) {
      String key = _getKey(ConfigurationOption.projectDirectory)!;
      _makeQuestion(key,
          'Please enter the full path to the project directory you want to use:');
      dialog.order!.add(key);
    }
  }

  void _maybeClarifyCustomWpBinary() {
    String? previousAnswer = _getAnswerByOption(previousAnswers, ConfigurationOption.wpBinaryType);
    if (previousAnswer == WpCliPresetOptions[WpCliType.custom]) {
      String key = _getKey(ConfigurationOption.wpBinary)!;
      _makeQuestion(key,
          'Please enter the full path to the custom wp-cli PHAR archive you wish to use:');
      dialog.order!.add(key);
    }
  }

  void _makeMessage(String key, String message) {
    this.dialog.addQuestion(message, key, is_message: true);
  }

  void _makeQuestion(String key, String question, [bool boolean = false]) {
    this.dialog.addQuestion(question, key, is_boolean: boolean);
  }

  void _makeListQuestion(String key, String question, List<String> options) {
    this.dialog.addQuestion({'question': question, 'options': options}, key,
        is_list: true);
  }

  bool _needsClarification(Map answers) {
    if (answers['projectPathPreset'] ==
        ProjectPathPresetOptions[ProjectPathPreset.custom]) {
      return true;
    }

    if (_getAnswerByOption(answers, ConfigurationOption.wpBinaryType) == WpCliPresetOptions[WpCliType.custom]) {
      return true;
    }

    return false;
  }
}
