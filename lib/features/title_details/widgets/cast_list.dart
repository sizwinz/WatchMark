import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';

class CastList extends StatelessWidget {
  final List<TmdbCastMember> cast;

  const CastList({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Cast & Crew',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final member = cast[index];
              final profileUrl = ApiEndpoints.profileUrl(member.profilePath);

              return SizedBox(
                width: 75,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                      child: profileUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profileUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.person, color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      member.character,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
