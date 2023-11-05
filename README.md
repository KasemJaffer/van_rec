# VanRec

VanRec, short for Vancouver Recreational Centers is an open source cross-platform app built using [Flutter](https://flutter.dev). 
It's aimed at providing users with access to an extensive catalog of Vancouver Park Board facilities within 
their local area. Whether you're interested in exploring indoor pools, outdoor golf 
courses, fitness centers, or skateboard parks, this app offers a resource for 
discovering these recreational amenities in your community.

Link: [Website](https://vanrec.kasem.dev)

![Alt Text](./screenshot-2.jpg)
<br><br>
![Alt Text](./screenshot-1.jpg)

## Getting Started
This project uses Supabase for storage. To get started. Go to https://supabase.com and create a project.
Get connection url and key, and put them inside `.env` file in the root folder of this project. 

Example `.env` file
```
SUPABASE_URL=https://lkajsdlkjasda.supabase.co
SUPABASE_KEY=asdasd.asdasd.asdasdasdasd
```

## Project File Structure
The entry point of the application is `lib/main.dart`.
```
lib/
├── main.dart
├── app_page.dart
├── router.dart
├── data/
│   ├── ds/
│   │   ├── supabase_data_source.dart
│   │   ├── data_source.dart
│   ├── repo/
│   │   ├── event_repository.dart
├── ui/
│   ├── vm/
│   │   ├── home_screen_vm.dart
│   │   ├── details_dialog_vm.dart
│   ├── view/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   ├── details/
│   │   │   ├── details_dialog.dart
│   ├── master/
│   │   ├── adaptive_navigation.dart
│   │   ├── root_layout.dart
├── shared/
│   ├── extensions.dart
│   ├── providers/
│   │   ├── providers.dart
│   │   ├── app_state.dart
│   │   ├── theme.dart
│   ├── utils/
│   │   ├── utils.dart
│   │   ├── throttler.dart
│   ├── logs/
│   │   ├── logger.dart
│   │   ├── output_file/
│   │   │   ├── output_file.dart
│   │   │   ├── file_output_web.dart
│   │   │   ├── file_output_mobile.dart
│   ├── views/
│   │   ├── outlined_card.dart
│   │   ├── dialogs.dart
│   │   ├── keyboard_actions.dart
│   │   ├── adaptive_popup.dart
│   │   ├── clickable.dart
│   │   ├── views.dart
│   │   ├── brightness_toggle.dart
│   │   ├── hover_toggle.dart
importer/
├── bin/
│   ├── importer.dart
├── lib/
│   ├── importer_impl.dart
│   ├── data/
│   │   ├── rec_center.dart
│   │   ├── center_activity.dart
│   │   ├── activity.dart
│   │   ├── data.dart
│   │   ├── my_event.dart
│   ├── utils/
│   │   ├── extensions.dart
test/
├── home_screen_vm_test.dart
├── details_dialog_vm_test.dart
.env
pubspec.yaml
```

## Database Schema
The project expects you to have a database with the following schema.
![Alt Text](./schema.jpg)

### Add Events Function (Stored Procedure)

Function name: `addEvents`
```sql
BEGIN
  INSERT INTO "Events"
    SELECT * FROM json_to_recordset(payload) as (
      id bigint, 
      "start" timestamp without time zone, 
      "end" timestamp without time zone, 
      "title" text, 
      "activityName" text, 
      "centerName" text,
      "description" text,  
      "allDay" boolean, 
      "activityId" bigint, 
      "centerId" bigint
  )
  ON CONFLICT ("id", "start", "end") 
  DO 
    UPDATE SET 
      "title" = excluded.title, 
      "description" = excluded.description, 
      "allDay" = excluded."allDay",
      "activityName" = excluded."activityName",
      "centerName" = excluded."centerName";
  RETURN TRUE;      
END;

```

## Google analytics
- To enable google analytics run the following command.
```
flutterfire configure
```

- If you don't need it, you can safely remove below line from `main.dart`
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## Populate Database

- Scrape and import Activities
```shell
dart importer/bin/importer.dart -a
```

- Scrape and import Centres
```shell
dart importer/bin/importer.dart -c
```

- Scrape and import Events
```shell
dart importer/bin/importer.dart -e
```

## Run Project
Once you have some data in the database you can run the project.
```
flutter run -d chrome
```