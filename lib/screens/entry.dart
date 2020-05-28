import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home.dart';
import '../models/data.dart';
import '../models/entry.dart';
import '../models/nav.dart';

void _launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class MyEntryHeader extends StatelessWidget {
  MyEntryHeader({Key key, @required this.entry}) : super(key: key);
  final Entry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            entry.title,
            textScaleFactor: 1.25,
            style: TextStyle(
              color: Theme.of(context).textTheme.title.color,
              fontWeight: Theme.of(context).textTheme.title.fontWeight,
            ),
          ),
          Divider(
            thickness: 1.0,
            color: Theme.of(context).textTheme.title.color,
          ),
          RichText(
            textScaleFactor: 0.75,
            text: TextSpan(
              style:
                  TextStyle(color: Theme.of(context).textTheme.subtitle.color),
              children: <TextSpan>[
                TextSpan(text: 'by '),
                TextSpan(
                    text: entry.author,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ', ' + Uri.parse(entry.url).host)
              ],
            ),
          ),
          Text(
            DateFormat.yMEd()
                .add_jm()
                .format(DateTime.parse(entry.publishedAt)),
            textScaleFactor: 0.75,
          ),
        ],
      ),
    );
  }
}

class MyEntryBody extends StatelessWidget {
  MyEntryBody({Key key, @required this.entry}) : super(key: key);
  final Entry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            MyEntryHeader(entry: entry),
            Html(
              data: entry.content,
              onLinkTap: (url) => _launchURL(url),
              onImageTap: (url) => _launchURL(url),
            ),
          ],
        ),
      ),
      onHorizontalDragEnd: (details) {
        // We need to filter entries from the complete list and not from the entries available in
        // the ListView.builder since the builder usually has a subset of entries (the ones
        // displayed).
        Entry nextEntry;
        final data = Provider.of<Data>(context, listen: false);
        final nav = Provider.of<Nav>(context, listen: false);
        final entries = filterEntries(data, nav);
        final index = entries.indexOf(entry);
        if (details.velocity.pixelsPerSecond.dx < 0 &&
            index < entries.length - 1) {
          nextEntry = entries[index + 1];
        } else if (details.velocity.pixelsPerSecond.dx > 0 && index > 0) {
          nextEntry = entries[index - 1];
        }
        if (nextEntry != null) {
          Navigator.pushReplacementNamed(
            context,
            '/entry',
            arguments: nextEntry,
          );
          final List<int> entryIds = [nextEntry.id];
          data.read(entryIds);
        }
      },
    );
  }
}

class MyEntryBottom extends StatelessWidget {
  MyEntryBottom({Key key, @required this.entry}) : super(key: key);
  final Entry entry;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      child: Row(
        children: <Widget>[
          Spacer(),
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                // The box is necessary for iPads
                final RenderBox box = context.findRenderObject();
                Share.share(entry.url,
                    subject: entry.title,
                    sharePositionOrigin:
                        box.localToGlobal(Offset.zero) & box.size);
              }),
          Consumer<Data>(
            builder: (context, data, child) {
              return IconButton(
                icon: entry.starred
                    ? Icon(
                        Icons.star,
                        color: Colors.amber,
                      )
                    : Icon(Icons.star_border),
                onPressed: () => data.toggleStar(entry.id),
              );
            },
          ),
          Consumer<Data>(
            builder: (context, data, child) {
              return IconButton(
                icon: Icon(entry.status == 'read'
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () => data.toggleRead(entry.id),
              );
            },
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class MyEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Entry entry = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.feed.title,
        ),
      ),
      body: MyEntryBody(entry: entry),
      bottomNavigationBar: MyEntryBottom(entry: entry),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.open_in_browser),
        onPressed: () => _launchURL(entry.url),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
