import 'package:cli_dialog/cli_dialog.dart';
import 'package:dcli/dcli.dart';

import '../argument-parser.dart';
import '../util/console-helper.dart';
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

class Wizard {
  final Config config;

  late CLI_Dialog dialog;
  late Map previousAnswers;

  List<String> dialogOrder = [];

  bool wantsComment = false;

  Wizard(this.config) {
    dialog = CLI_Dialog();

    _maybeAskMode();
    _maybeAskOperation();
    _maybeAskProjectDirectoryPreset();
    _maybeAskVerbosity();

    dialog.order = dialogOrder;
    dialogOrder = <String>[];
  }

  Config run() {
    Map answers = dialog.ask();
    _applyAnswersToConfiguration(answers);

    _askDetails();
    if (_needsClarification(answers)) {
      _clarify(answers);
    }

    return this.config;
  }

  void _askDetails() {
    dialog = CLI_Dialog();

    _maybeAskComment();
    _maybeAskBackupBeforeRestore();

    if (dialogOrder.length > 0) {
      dialog.order = dialogOrder;
      dialogOrder = <String>[];

      Map answers = dialog.ask();
      _applyDetailsToConfiguration(answers);
    }
  }

  void _clarify(Map previousAnswers) {
    dialog = CLI_Dialog();
    this.previousAnswers = previousAnswers;

    _maybeClarifyCustomProjectDirectory();
    _maybeClarifyComment();

    dialog.order = dialogOrder;
    dialogOrder = <String>[];

    Map answers = dialog.ask();

    _applyClarificationToConfiguration(answers);
  }

  void _applyAnswersToConfiguration(Map answers) {
    config.mode ??= answers['mode'];

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

    if (!config.hasProjectDirectoryBeenEdited) {
      var selection = answers['projectPathPreset'];

      if (selection == ProjectPathPresetOptions[ProjectPathPreset.cwd]) {
        config.projectDirectory = 'realpath .'.firstLine ?? '.';
      } else if (selection ==
          ProjectPathPresetOptions[ProjectPathPreset.userHome]) {
        config.projectDirectory =
            ConsoleHelper().userdoFirstLine('realpath \$HOME')!;
      }
    }
  }

  void _applyClarificationToConfiguration(Map answers) {
    if (previousAnswers['projectPathPreset'] ==
        ProjectPathPresetOptions[ProjectPathPreset.custom]) {
      config.projectDirectory =
          answers[_getKey(ConfigurationOption.projectDirectory)];
    }

    if (_isBackup() && wantsComment) {
      config.comment = _getAnswerByOption(answers, ConfigurationOption.comment);
    }
  }

  void _applyDetailsToConfiguration(Map answers) {
    if (_isBackup()) {
      wantsComment = _getAnswerByOption(answers, ConfigurationOption.comment);
    } else {
      config.backupBeforeRestore =
          _getAnswerByOption(answers, ConfigurationOption.backupBeforeRestore);
    }
  }

  _getAnswerByOption(answers, option) {
    return answers[_getKey(option)];
  }

  bool _getFlagByOption(answers, option) {
    var answerGiven = answers[_getKey(option)];
    return answerGiven != null ? answerGiven : false;
  }

  String _getKey(ConfigurationOption option) {
    return Config.getParameter(option);
  }

  void _maybeAskComment() {
    if (!_isBackup()) return;

    if (config.comment == null) {
      String key = _getKey(ConfigurationOption.comment);
      _makeQuestion(
          key, 'Would you like to add a tag / comment to the filename?', true);

      dialogOrder.add(key);
    }
  }

  void _maybeAskBackupBeforeRestore() {
    if (_isBackup()) return;

    String key = _getKey(ConfigurationOption.backupBeforeRestore);
    _makeQuestion(
        key,
        'Shall we create a new backup of the status quo before restoring?',
        true);
    dialogOrder.add(key);
  }

  void _maybeAskMode() {
    if (config.mode == null) {
      String key = 'mode';

      _makeListQuestion(key, 'Select what it is you would like to do:',
          [Commands.backup, Commands.restore]);
      dialogOrder.add(key);
    }
  }

  /**
   * Ask the user which backup operation to perform if it's not provided yet.
   */
  void _maybeAskOperation() {
    String key = _getKey(ConfigurationOption.operation);

    if (!config.hasOperation()) {
      _makeListQuestion(key, 'What is it you would like to back up?', <String>[
        OperationSelectionOptions[OperationType.all]!,
        OperationSelectionOptions[OperationType.database]!,
        OperationSelectionOptions[OperationType.userdata]!,
      ]);
    } else {
      _makeMessage(key, 'Operation ${config.operation} selected.');
    }

    dialogOrder.add(key);
  }

  /**
   * Ask the user whether to use the CWD, their $HOME or a custom directory,
   * unless one has been provided.
   */
  void _maybeAskProjectDirectoryPreset() {
    if (!config.hasProjectDirectoryBeenEdited) {
      String key = 'projectPathPreset';

      _makeListQuestion(key, 'Where is your Wordpress deployment located?', [
        ProjectPathPresetOptions[ProjectPathPreset.cwd]!,
        ProjectPathPresetOptions[ProjectPathPreset.userHome]!,
        ProjectPathPresetOptions[ProjectPathPreset.custom]!,
      ]);

      dialogOrder.add(key);
    }
  }

  void _maybeAskVerbosity() {
    if (!config.verbose) {
      String key = _getKey(ConfigurationOption.verbose);
      _makeQuestion(key, 'Would you like to enable verbose output?', true);
      dialogOrder.add(key);
    }
  }

  void _maybeClarifyComment() {
    if (wantsComment) {
      String key = _getKey(ConfigurationOption.comment);
      _makeQuestion(
          key, 'Please specify the tag / comment (will-be-slugified).');
      dialogOrder.add(key);
    }
  }

  void _maybeClarifyCustomProjectDirectory() {
    if (previousAnswers['projectPathPreset'] ==
        ProjectPathPresetOptions[ProjectPathPreset.custom]) {
      String key = _getKey(ConfigurationOption.projectDirectory);
      _makeQuestion(key,
          'Please enter the full path to the project directory you want to use:');
      dialogOrder.add(key);
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

    if (wantsComment) {
      return true;
    }

    return false;
  }

  bool _isBackup() {
    return config.mode == Commands.backup;
  }
}
