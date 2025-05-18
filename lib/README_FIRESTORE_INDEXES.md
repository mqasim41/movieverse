# MovieVerse Firestore Indexes Setup

This application requires specific Firestore indexes to function properly. If you encounter any errors related to missing indexes, follow the instructions below.

## Required Composite Indexes

Based on the error messages, the following composite indexes need to be created:

### Favorites Collection
- **Fields**: 
  - `userId` (Ascending)
  - `addedAt` (Descending)
  - `__name__` (Descending)

### Watch History Collection
- **Fields**:
  - `userId` (Ascending)
  - `watchedAt` (Descending)

## How to Create Indexes

### Option 1: Use the Direct Link from Error Messages

When the app shows an error about missing indexes, it provides a direct link like:
```
https://console.firebase.google.com/v1/r/project/movieverse-b959c/firestore/indexes?create_composite=ClJwcm9qZWN0cy9tb3ZpZXZlcnNlLWI5NTljL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9mYXZvcml0ZXMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaCwoHYWRkZWRBdBACGgwKCF9fbmFtZV9fEAI
```

Simply click this link to be taken directly to the Firebase Console where you can create the index with a single click.

### Option 2: Manual Creation

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database
4. Select the "Indexes" tab
5. Click "Create Index"
6. Select the appropriate collection ("favorites" or "watchHistory")
7. Add the fields in the order mentioned above
8. Set the Query scope to "Collection"
9. Click "Create"

## Testing the Indexes

After creating the indexes, it might take a few minutes for them to be fully built and deployed. Once the indexes are active, the error messages should disappear, and the app should function correctly.

## Temporary Fallback Solutions

The app has fallback mechanisms to handle missing indexes, but they may not provide the optimal user experience:

- When indexes are missing, the app will still fetch data but may not be able to sort it correctly
- You'll see warning messages in the console when fallbacks are being used
- The app will continue to remind you to create the required indexes

## Support

If you continue to experience issues with Firestore indexes after following these instructions, please check the [Firebase documentation](https://firebase.google.com/docs/firestore/query-data/indexing) or contact support. 