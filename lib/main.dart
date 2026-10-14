import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RpgDiceApp());
}

/// Widget principal da aplicação.
class RpgDiceApp extends StatelessWidget {
  const RpgDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RPG Dice Roller',

      // Configuração visual do aplicativo.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Fundo escuro.
        scaffoldBackgroundColor: const Color(0xFF0B0E14),

        // Cores principais do aplicativo.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.dark,
          primary: const Color(0xFFE53935), // Vermelho
          secondary: const Color(0xFF42A5F5), // Azul
          surface: const Color(0xFF151A24),
        ),

        // Aparência dos campos de texto.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151A24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF303847),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF42A5F5),
              width: 2,
            ),
          ),
        ),

        // Aparência dos cartões.
        cardTheme: CardThemeData(
          color: const Color(0xFF151A24),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // Primeira tela da aplicação.
      home: const DiceHomePage(),
    );
  }
}

/// Modelo que representa uma rolagem de dados.
class DiceRoll {
  const DiceRoll({
    required this.notation,
    required this.results,
    required this.total,
    required this.createdAt,
  });

  /// Exemplo: 2d20+5.
  final String notation;

  /// Resultados individuais. Exemplo: [12, 8].
  final List<int> results;

  /// Soma final da rolagem.
  final int total;

  /// Data e hora da rolagem.
  final DateTime createdAt;

  /// Converte o objeto para um mapa.
  ///
  /// O mapa será convertido para JSON antes de ser salvo.
  Map<String, dynamic> toMap() {
    return {
      'notation': notation,
      'results': results,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Cria um objeto DiceRoll a partir de um mapa salvo.
  factory DiceRoll.fromMap(Map<String, dynamic> map) {
    final rawResults = map['results'] as List<dynamic>;

    return DiceRoll(
      notation: map['notation'] as String,
      results: rawResults.map((value) => value as int).toList(),
      total: map['total'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// Tela principal do aplicativo.
class DiceHomePage extends StatefulWidget {
  const DiceHomePage({super.key});

  @override
  State<DiceHomePage> createState() {
    return _DiceHomePageState();
  }
}

class _DiceHomePageState extends State<DiceHomePage> {
  /// Gerador de números aleatórios.
  final Random _random = Random();

  /// Controla o campo de quantidade de dados.
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  /// Controla o campo de modificador.
  final TextEditingController _modifierController =
      TextEditingController(text: '0');

  /// Dados disponíveis para escolha.
  final List<int> _diceSides = [4, 6, 8, 10, 12, 20, 100];

  /// Dado selecionado inicialmente.
  int _selectedSides = 20;

  /// Total da última rolagem.
  int _total = 0;

  /// Resultados individuais da última rolagem.
  List<int> _currentResults = [];

  /// Histórico de todas as rolagens.
  List<DiceRoll> _history = [];

  /// Indica se o histórico ainda está sendo carregado.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Carrega o histórico assim que a tela é criada.
    _loadHistory();
  }

  @override
  void dispose() {
    // Libera os controladores quando a tela é fechada.
    _quantityController.dispose();
    _modifierController.dispose();

    super.dispose();
  }

  /// Carrega o histórico salvo no navegador.
  Future<void> _loadHistory() async {
    final preferences = await SharedPreferences.getInstance();

    final savedHistory = preferences.getString('dice_history');

    // Não existe histórico salvo ainda.
    if (savedHistory == null || savedHistory.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    try {
      // Converte o texto JSON para uma lista.
      final decodedHistory = jsonDecode(savedHistory) as List<dynamic>;

      // Converte cada item para DiceRoll.
      final loadedRolls = decodedHistory
          .map(
            (item) => DiceRoll.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _history = loadedRolls;
        _isLoading = false;
      });
    } catch (error) {
      // Caso o conteúdo salvo esteja corrompido,
      // o aplicativo começa com histórico vazio.
      debugPrint('Erro ao carregar histórico: $error');

      if (mounted) {
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Salva o histórico no armazenamento local.
  Future<void> _saveHistory() async {
    final preferences = await SharedPreferences.getInstance();

    // Converte cada rolagem para mapa.
    final historyAsMap = _history.map((roll) {
      return roll.toMap();
    }).toList();

    // Converte a lista para texto JSON.
    final encodedHistory = jsonEncode(historyAsMap);

    // Salva no navegador usando uma chave.
    await preferences.setString(
      'dice_history',
      encodedHistory,
    );
  }

  /// Realiza uma nova rolagem.
  Future<void> _rollDice() async {
    // Tenta converter a quantidade digitada para inteiro.
    final quantity =
        int.tryParse(_quantityController.text.trim()) ?? 1;

    // Tenta converter o modificador digitado para inteiro.
    final modifier =
        int.tryParse(_modifierController.text.trim()) ?? 0;

    // Garante que a quantidade fique entre 1 e 20.
    //
    // O toInt() é importante porque clamp pode retornar num.
    final safeQuantity = quantity.clamp(1, 20).toInt();

    // Cria os resultados aleatórios.
    final results = List<int>.generate(
      safeQuantity,
      (index) {
        // nextInt(_selectedSides) gera de 0 até sides - 1.
        // Somando 1, o resultado fica de 1 até sides.
        return _random.nextInt(_selectedSides) + 1;
      },
    );

    // Soma os resultados individuais.
    final diceTotal = results.fold<int>(
      0,
      (currentTotal, value) {
        return currentTotal + value;
      },
    );

    // Adiciona o modificador.
    final total = diceTotal + modifier;

    // Cria o texto do modificador.
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';

    // Cria o objeto da nova rolagem.
    final newRoll = DiceRoll(
      notation: '${safeQuantity}d$_selectedSides$modifierText',
      results: results,
      total: total,
      createdAt: DateTime.now(),
    );

    if (!mounted) {
      return;
    }

    // Atualiza o resultado e adiciona a rolagem ao histórico.
    setState(() {
      _currentResults = results;
      _total = total;
      _history.insert(0, newRoll);
    });

    // Salva o histórico atualizado.
    await _saveHistory();
  }

  /// Apaga uma rolagem específica.
  Future<void> _deleteRoll(int index) async {
    setState(() {
      _history.removeAt(index);
    });

    await _saveHistory();
  }

  /// Apaga todo o histórico.
  Future<void> _clearHistory() async {
    if (_history.isEmpty) {
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar histórico?'),
          content: const Text(
            'Todas as rolagens salvas serão removidas.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('dice_history');

    if (!mounted) {
      return;
    }

    setState(() {
      _history = [];
    });
  }

  /// Formata a hora da rolagem.
  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.casino_rounded),
            SizedBox(width: 10),
            Text('RPG Dice Roller'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearHistory,
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24,
                ),
                children: [
                  _buildResultCard(),
                  const SizedBox(height: 18),
                  _buildControlsCard(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  /// Cria o cartão que mostra o resultado.
  Widget _buildResultCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF56151B),
              Color(0xFF123458),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_total',
              style: const TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentResults.isEmpty
                  ? 'Configure e role os dados'
                  : 'Resultados: ${_currentResults.join(' • ')}',
              style: TextStyle(
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cria o cartão com os controles de rolagem.
  Widget _buildControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurar rolagem',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tipo de dado',
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 10),

            // Botões d4, d6, d8, d10, d12, d20 e d100.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _diceSides.map(
                (side) {
                  return ChoiceChip(
                    label: Text('d$side'),
                    selected: _selectedSides == side,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSides = side;
                      });
                    },
                  );
                },
              ).toList(),
            ),

            const SizedBox(height: 18),

            // Campos de quantidade e modificador.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      prefixIcon: Icon(Icons.filter_1_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _modifierController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Modificador',
                      prefixIcon: Icon(Icons.add_rounded),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Botão principal.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _rollDice,
                icon: const Icon(Icons.casino_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('ROLAR DADOS'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cria a seção do histórico.
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Histórico local',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_history.length} rolagem(ns)',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_history.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Center(
                child: Text(
                  'Nenhuma rolagem salva ainda.',
                ),
              ),
            ),
          )
        else
          ..._history.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final roll = entry.value;

              return _buildHistoryItem(
                roll: roll,
                index: index,
              );
            },
          ),
      ],
    );
  }

  /// Cria um item do histórico.
  Widget _buildHistoryItem({
    required DiceRoll roll,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: const Icon(Icons.casino_rounded),
          ),
          title: Text(
            roll.notation,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${roll.results.join(', ')} • '
            '${_formatTime(roll.createdAt)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${roll.total}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  _deleteRoll(index);
                },
                tooltip: 'Excluir rolagem',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
