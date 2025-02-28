import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/components/record_type_bottom_sheet.dart';
import '/common/provider.dart';
import '/common/api.dart';
import '/common/record/record.dart';

class TodayContent extends StatelessWidget {
  Future<Map<String, dynamic>> _getUserInfo(BuildContext context) async {
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    final userInfo = await appDataProvider.getData('userInfo');
    return userInfo ?? {};
  }

  void _deleteRecord(BuildContext context, String recordId) async {
    var dayRecord = Provider.of<AppDataProvider>(context, listen: false).getData('dayrecord');
    var pid = dayRecord['id'];

    Map<String, dynamic> postData = {
      'pid': pid,
      'id': recordId,
    };

    try {
      await deleteDayrecordDetail(postData);
      Provider.of<AppDataProvider>(context, listen: false).fetchDayRecord();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('记录已删除', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF00F5E1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    final userInfo = appDataProvider.getData('userInfo');

    if (userInfo == null) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF00F5E1)));
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String formattedDayOfWeek = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: Color(0xFF000000),
              flexibleSpace: Padding(
                padding: const EdgeInsets.all(0.0),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  collapseMode: CollapseMode.parallax,
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      double top = constraints.biggest.height;
                      if (top <= kToolbarHeight) {
                        return Text(
                          "今天的记录",
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  ),
                  background: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Color(0xFF1A1A1A),
                        ),
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.2,
                            child: Image.asset(
                              "assets/img/banner/today_banner.jpg",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今天是：$formattedDate',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '星期$formattedDayOfWeek',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFAAAAAA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ];
        },
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Consumer<AppDataProvider>(
                builder: (context, appDataProvider, child) {
                  var dayRecord = appDataProvider.getData('dayrecord');
                  List<Map<String, dynamic>> records = [];
                  if (dayRecord['record'] != null) {
                    records = List<Map<String, dynamic>>.from(dayRecord['record']);
                  }

                  var length = dayRecord['record']?.length ?? 0;

                  return ListView(
                    children: [
                      SizedBox(height: 36),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '今日记录 $length 条',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                            SizedBox(height: 16),
                            records.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    height: 400,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/img/banner/nodata.png',
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.contain,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          '今天还没有记录哦，快来添加吧！',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: records.map((record) {
                                      var typeInfo = recordTypeOptions.firstWhere(
                                        (item) => item['type'] == record['type'],
                                        orElse: () => {
                                          'label': '未知',
                                          'logo': 'assets/img/default.png'
                                        },
                                      );

                                      Widget customContent;
                                      switch (record['type']) {
                                        case 'sleep':
                                          customContent = Text(
                                            '睡眠质量: ${record['quality'] ?? '未知'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF666666),
                                            ),
                                          );
                                          break;
                                        case 'mood':
                                          customContent = Text(
                                            '心情指数: ${record['moodLevel'] ?? '未知'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF666666),
                                            ),
                                          );
                                          break;
                                        case 'diet':
                                          customContent = Text(
                                            '饮食情况: ${record['mealDetails'] ?? '未知'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF666666),
                                            ),
                                          );
                                          break;
                                        case 'exercise':
                                          customContent = Text(
                                            '运动时长: ${record['duration'] ?? '未知'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF666666),
                                            ),
                                          );
                                          break;
                                        case 'fragment':
                                          customContent = Text(
                                            '碎片: ${record['duration'] ?? '未知'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF666666),
                                            ),
                                          );
                                          break;
                                        default:
                                          customContent = SizedBox();
                                      }

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 12),
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF1A1A1A),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              offset: Offset(0, 4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              typeInfo['logo'],
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    typeInfo['label'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFFFFFFF),
                                                    ),
                                                  ),
                                                  Text(
                                                    '时间: ${record['createTime'] ?? '未知'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF666666),
                                                    ),
                                                  ),
                                                  Text(
                                                    '内容: ${record['content'] ?? '无内容'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF666666),
                                                    ),
                                                  ),
                                                  customContent,
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Color(0xFFFF2D55)),
                                              onPressed: () {
                                                _deleteRecord(context, record['id']);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00F5E1), // Teal background
                    foregroundColor: Colors.black, // Black text/icon
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // Rounded corners
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_calendar, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '添加记录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return RecordTypeBottomSheet(
          onOptionSelected: (selectType) {
            String routeName = '${selectType}Record';
            if (routeName.isNotEmpty) {
              Navigator.pushNamed(context, routeName);
            }
          },
        );
      },
    );
  }
}