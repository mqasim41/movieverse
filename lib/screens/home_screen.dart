import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/movie_card.dart';
import '../widgets/common/app_bar.dart';
import '../widgets/common/poster_image.dart';
import '../widgets/common/rating_badge.dart';
import '../config/theme.dart';
import 'profile_screen.dart';
import 'movie_detail_screen.dart';
import '../models/movie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showLegend = true;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we need to load data
      final vm = context.read<HomeViewModel>();
      if (vm.popular.isEmpty && !vm.isLoading) {
        vm.loadPopular();
      }
    });
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
                  await vm.loadRecommendations();
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
                            // Icon legend (only show when user is logged in and on main screen)
                            if (FirebaseAuth.instance.currentUser != null &&
                                _selectedIndex == 0 &&
                                _showLegend)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppTheme.paddingMedium),
                                  child: Card(
                                    color: theme.colorScheme.surface,
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppTheme.paddingMedium),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Movie Actions',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    _showLegend = false;
                                                  });
                                                },
                                                tooltip: 'Dismiss',
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildLegendItem(
                                                  icon: Icons.favorite,
                                                  color: Colors.red,
                                                  label: 'Add to Favorites',
                                                  description:
                                                      'Movies you love and want to save',
                                                  theme: theme,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildLegendItem(
                                                  icon: Icons.visibility,
                                                  color: Colors.green,
                                                  label: 'Mark as Watched',
                                                  description:
                                                      'Movies you have seen',
                                                  theme: theme,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          Center(
                                            child: Text(
                                              'Tap a movie to see details and manage your watch status',
                                              style: theme.textTheme.bodySmall,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            if (_selectedIndex == 0 &&
                                vm.recommendations.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppTheme.paddingMedium,
                                        AppTheme.paddingMedium,
                                        AppTheme.paddingMedium,
                                        AppTheme.paddingSmall,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.recommend,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Recommended For You',
                                                style:
                                                    theme.textTheme.titleLarge,
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.refresh),
                                            onPressed: () {
                                              vm.loadRecommendations();
                                            },
                                            tooltip: 'Refresh recommendations',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 180,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              AppTheme.paddingMedium / 2,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: vm.recommendations.length,
                                        itemBuilder: (context, index) {
                                          final movie =
                                              vm.recommendations[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  AppTheme.paddingSmall / 2,
                                              vertical:
                                                  AppTheme.paddingSmall / 2,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        MovieDetailScreen(
                                                            movie: movie),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 280,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppTheme.radiusMedium,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      blurRadius: 5,
                                                      offset:
                                                          const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: Stack(
                                                  children: [
                                                    // Backdrop/poster image as background
                                                    Positioned.fill(
                                                      child: PosterImage(
                                                        posterPath:
                                                            movie.posterPath,
                                                        showShadow: false,
                                                      ),
                                                    ),
                                                    // Gradient overlay for better text visibility
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              Colors
                                                                  .transparent,
                                                              Colors.black
                                                                  .withOpacity(
                                                                      0.7),
                                                            ],
                                                            stops: const [
                                                              0.6,
                                                              1.0
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Rating badge
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: RatingBadge(
                                                        rating: movie.rating,
                                                        size: RatingBadgeSize
                                                            .medium,
                                                      ),
                                                    ),
                                                    // Movie info at bottom
                                                    Positioned(
                                                      left: 12,
                                                      right: 12,
                                                      bottom: 10,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            movie.title,
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (movie
                                                                  .releaseYear !=
                                                              null)
                                                            Text(
                                                              movie.releaseYear
                                                                  .toString(),
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppTheme.paddingMedium,
                                        AppTheme.paddingMedium,
                                        AppTheme.paddingMedium,
                                        AppTheme.paddingSmall,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.movie_outlined,
                                            color: theme.colorScheme.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Popular Movies',
                                            style: theme.textTheme.titleLarge,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
              vm.loadRecommendations();
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
              onPressed: () {
                final vm = context.read<HomeViewModel>();
                vm.loadPopular();
              },
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

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
