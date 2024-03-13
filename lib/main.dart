import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const BiomesApp());
}

const kMapSize = 10;

class BiomesApp extends StatelessWidget {
  const BiomesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biomes',
      theme: ThemeData(brightness: Brightness.dark),
      home: const BiomesPage(),
    );
  }
}

final rand = Random();

class BiomesPage extends StatefulWidget {
  const BiomesPage({super.key});

  @override
  State<BiomesPage> createState() => _BiomesPageState();
}

class _BiomesPageState extends State<BiomesPage> {
  List<List<int>>? worldmap;
  List<List<(int, int)>>? biomes;

  int? selectedBiomeIndex;

  List<(int, int)>? get highlighted {
    if (selectedBiomeIndex == null) {
      return null;
    }

    if (biomes == null) {
      return null;
    }

    return biomes![selectedBiomeIndex!];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: generateMap,
                  child: const Text('Generate map'),
                ),
                if (worldmap != null) ...[
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: scanBiomes,
                    child: const Text('Scan biomes'),
                  ),
                ]
              ],
            ),
          ),
          Expanded(
            child: Flex(
              direction: MediaQuery.of(context).size.aspectRatio > 1
                  ? Axis.horizontal
                  : Axis.vertical,
              children: [
                if (worldmap != null)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: WorldMap(
                        biomes: worldmap!,
                        highlighted: highlighted,
                      ),
                    ),
                  ),
                if (biomes != null)
                  Expanded(
                    flex: 1,
                    child: BiomesList(
                      biomes: biomes!,
                      worldmap: worldmap!,
                      selectedIndex: selectedBiomeIndex,
                      onBiomeSelected: (index) {
                        setState(() {
                          selectedBiomeIndex = index;
                        });
                      },
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  void generateMap() {
    final biomes = <List<int>>[];

    for (int i = 0; i < kMapSize; i++) {
      biomes.add([]);

      for (int j = 0; j < kMapSize; j++) {
        biomes[i].add(rand.nextInt(4));
      }
    }

    setState(() {
      worldmap = biomes;

      this.biomes = null;
      selectedBiomeIndex = null;
    });
  }

  void scanBiomes() {
    if (worldmap == null) {
      return;
    }

    final biomes = getBiomes(worldmap!);

    setState(() {
      this.biomes = biomes.toList();
    });
  }
}

class WorldMap extends StatelessWidget {
  final List<List<int>> biomes;
  final List<(int, int)>? highlighted;

  const WorldMap({
    super.key,
    required this.biomes,
    this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final tileSize = constraints.maxWidth / kMapSize;

        return Stack(
          children: [
            for (int i = 0; i < kMapSize; i++)
              for (int j = 0; j < kMapSize; j++)
                Positioned(
                  left: j * tileSize,
                  top: i * tileSize,
                  child: BiomeTile(
                    biome: biomes[i][j],
                    size: tileSize,
                  ),
                ),
            if (highlighted != null)
              for (final (x, y) in highlighted!)
                Positioned(
                  left: y * tileSize,
                  top: x * tileSize,
                  child: Container(
                    width: tileSize,
                    height: tileSize,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
          ],
        );
      }),
    );
  }
}

const biomeSymbols = ['🌲', '🌳', '🌸', '🏝️'];

class BiomeTile extends StatelessWidget {
  final int biome;
  final double size;

  const BiomeTile({
    super.key,
    required this.biome,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: size,
      height: size,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Text(
          biomeSymbols[biome],
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );
  }
}

class BiomesList extends StatelessWidget {
  final List<List<int>> worldmap;
  final List<List<(int, int)>> biomes;
  final void Function(int) onBiomeSelected;
  final int? selectedIndex;

  const BiomesList({
    super.key,
    required this.biomes,
    required this.worldmap,
    required this.onBiomeSelected,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Click to select a biome',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: biomes.length,
            itemBuilder: (context, index) {
              final biome = biomes[index];
              final (x, y) = biome.first;

              return ListTile(
                selected: index == selectedIndex,
                title: Text('Biome ${biomeSymbols[worldmap[x][y]]}'),
                onTap: () {
                  onBiomeSelected(index);
                },
              );
            },
          ),
        )
      ],
    );
  }
}

final visited = <(int, int)>{};

Iterable<List<(int, int)>> getBiomes(List<List<int>> worldmap) sync* {
  visited.clear();

  for (int i = 0; i < worldmap.length; i++) {
    for (int j = 0; j < worldmap[i].length; j++) {
      if (visited.contains((i, j))) {
        continue;
      }

      yield traverse(worldmap, [(i, j)]);
    }
  }
}

List<(int, int)> traverse(
  List<List<int>> matrix,
  List<(int, int)> biome,
) {
  final last = biome.last;
  final (x, y) = last;

  visited.add((x, y));

  if (x < 0 || x >= matrix.length || y < 0 || y >= matrix[x].length) {
    return biome;
  }

  final current = matrix[x][y];

  // top
  if (x > 0 && matrix[x - 1][y] == current && !visited.contains((x - 1, y))) {
    biome.add((x - 1, y));
    traverse(matrix, biome);
  }

  // right
  if (y < matrix[x].length - 1 &&
      matrix[x][y + 1] == current &&
      !visited.contains((x, y + 1))) {
    biome.add((x, y + 1));
    traverse(matrix, biome);
  }

  // bottom
  if (x < matrix.length - 1 &&
      matrix[x + 1][y] == current &&
      !visited.contains((x + 1, y))) {
    biome.add((x + 1, y));
    traverse(matrix, biome);
  }

  // left
  if (y > 0 && matrix[x][y - 1] == current && !visited.contains((x, y - 1))) {
    biome.add((x, y - 1));
    traverse(matrix, biome);
  }

  return biome;
}
