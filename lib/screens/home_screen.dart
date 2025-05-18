import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/movie_card.dart';
import '../widgets/common/app_bar.dart';
import '../config/theme.dart';
import 'profile_screen.dart';
import '../models/movie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final vm = context.read<HomeViewModel>();
    await vm.loadPopular();
    await vm.loadFavorites();

    // Preloading removed for now as it might be causing issues
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: _selectedIndex == 3
          ? const ProfileScreen()
          : RefreshIndicator(
              onRefresh: () async {
                if (_selectedIndex == 0) {
                  await vm.loadPopular();
                } else if (_selectedIndex == 2) {
                  await vm.loadFavorites();
                }
              },
              child: _isLoading(vm)
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError(vm)
                      ? _buildErrorWidget(vm.error!)
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding:
                                  const EdgeInsets.all(AppTheme.paddingMedium),
                              sliver: _selectedIndex == 0
                                  ? _buildMovieGrid(vm.popular, theme)
                                  : _selectedIndex == 1
                                      ? _buildSearchResults(vm, theme)
                                      : _buildFavorites(vm.favorites, theme),
                            ),
                          ],
                        ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (_isSearching) {
              _isSearching = false;
            }

            // Load data for the selected tab
            if (index == 0) {
              vm.loadPopular();
            } else if (index == 2) {
              vm.loadFavorites();
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return SearchAppBar(
        controller: _searchController,
        hintText: 'Search movies...',
        onCancel: () {
          setState(() {
            _isSearching = false;
          });
        },
        onSubmitted: (query) {
          final vm = context.read<HomeViewModel>();
          vm.searchMovies(query);
        },
      );
    } else {
      return MovieVerseAppBar(
        title: _getAppBarTitle(),
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _selectedIndex = 1; // Switch to search tab
                });
              },
            ),
          if (_selectedIndex != 3)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Show filter options
              },
            ),
        ],
      );
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'MovieVerse';
      case 1:
        return 'Search';
      case 2:
        return 'Favorites';
      case 3:
        return 'Profile';
      default:
        return 'MovieVerse';
    }
  }

  bool _isLoading(HomeViewModel vm) {
    // Only show loading indicator for the current tab
    if (_selectedIndex == 0) {
      return vm.isLoading && vm.popular.isEmpty;
    } else if (_selectedIndex == 1) {
      return vm.isLoading && vm.searchResults.isEmpty;
    } else if (_selectedIndex == 2) {
      return vm.isLoading && vm.favorites.isEmpty;
    }
    return false;
  }

  bool _hasError(HomeViewModel vm) {
    return vm.error != null;
  }

  Widget _buildErrorWidget(String errorMessage) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid(List<Movie> movies, ThemeData theme) {
    if (movies.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No movies found',
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0, // Max width per item
        mainAxisSpacing: AppTheme.paddingMedium,
        crossAxisSpacing: AppTheme.paddingMedium,
        // Increase fixed height for each grid item
        mainAxisExtent: 300.0, // Larger fixed height to ensure no overflow
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => MovieCard(movie: movies[index]),
        childCount: movies.length,
      ),
    );
  }

  Widget _buildSearchResults(HomeViewModel vm, ThemeData theme) {
    if (_searchController.text.isEmpty) {
      // Placeholder for search
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'Search for movies',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Enter a title, actor, or genre',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_filter,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'No results found',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Try a different search term',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildMovieGrid(vm.searchResults, theme);
  }

  Widget _buildFavorites(List<Movie> favorites, ThemeData theme) {
    if (favorites.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'No favorites yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Movies you like will appear here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildMovieGrid(favorites, theme);
  }
}
