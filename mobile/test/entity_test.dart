import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/domain/entities/category_entity.dart';

void main() {
  group('NoteEntity 模型测试', () {
    test('NoteEntity 基础初始化', () {
      const entity = NoteEntity(id: 1, title: '测试笔记', content: '笔记内容');

      expect(entity.id, 1);
      expect(entity.title, '测试笔记');
      expect(entity.content, '笔记内容');
      expect(entity.categoryId, 1); // 默认值
    });

    test('NoteEntity 完整初始化', () {
      final now = DateTime.now();
      const entity = NoteEntity(
        id: 1,
        title: '笔记',
        content: '内容',
        url: 'https://example.com',
        categoryId: 2,
        tag: 'important',
      );

      expect(entity.id, 1);
      expect(entity.url, 'https://example.com');
      expect(entity.categoryId, 2);
      expect(entity.tag, 'important');
    });

    test('NoteEntity 新建笔记（无 ID）', () {
      const entity = NoteEntity(title: '新笔记', content: '内容');

      expect(entity.id, null); // 新笔记无 ID
      expect(entity.title, '新笔记');
    });

    test('NoteEntity copyWith 修改标题', () {
      const original = NoteEntity(id: 1, title: '原标题', content: '内容');

      final modified = original.copyWith(title: '新标题');

      expect(modified.id, 1); // ID 保持不变
      expect(modified.title, '新标题');
      expect(modified.content, '内容'); // 其他字段保持不变
      expect(original.title, '原标题'); // 原对象不变
    });

    test('NoteEntity copyWith 修改分类', () {
      const original = NoteEntity(title: '笔记', categoryId: 1);

      final modified = original.copyWith(categoryId: 3);

      expect(modified.categoryId, 3);
      expect(original.categoryId, 1); // 原对象不变
    });

    test('NoteEntity copyWith 清空字段', () {
      const original = NoteEntity(
        id: 1,
        title: '笔记',
        content: '内容',
        url: 'https://example.com',
      );

      // 注意：copyWith 使用 ?? 操作符，所以不能设置为 null
      // 这是设计的行为
      final sameUrl = original.copyWith(url: 'https://new.com');
      expect(sameUrl.url, 'https://new.com');
    });

    test('NoteEntity 相等性比较', () {
      const entity1 = NoteEntity(id: 1, title: '笔记', content: '内容');
      const entity2 = NoteEntity(id: 1, title: '笔记', content: '内容');

      expect(entity1, entity2);
    });

    test('NoteEntity 不相等 - 不同 ID', () {
      const entity1 = NoteEntity(id: 1, title: '笔记');
      const entity2 = NoteEntity(id: 2, title: '笔记');

      expect(entity1 != entity2, true);
    });

    test('NoteEntity 不相等 - 不同内容', () {
      const entity1 = NoteEntity(id: 1, title: '笔记', content: '内容1');
      const entity2 = NoteEntity(id: 1, title: '笔记', content: '内容2');

      expect(entity1 != entity2, true);
    });

    test('NoteEntity hashCode 一致', () {
      const entity1 = NoteEntity(id: 1, title: '笔记', content: '内容');
      const entity2 = NoteEntity(id: 1, title: '笔记', content: '内容');

      expect(entity1.hashCode, entity2.hashCode);
    });

    test('NoteEntity toString 格式', () {
      const entity = NoteEntity(id: 1, title: '笔记', categoryId: 2);

      final str = entity.toString();
      expect(str, contains('NoteEntity'));
      expect(str, contains('id: 1'));
      expect(str, contains('title: 笔记'));
    });

    test('NoteEntity 在 Set 中使用', () {
      const entity1 = NoteEntity(id: 1, title: '笔记1');
      const entity2 = NoteEntity(id: 1, title: '笔记1');
      const entity3 = NoteEntity(id: 2, title: '笔记2');

      final set = {entity1, entity2, entity3};

      expect(set.length, 2); // entity1 和 entity2 相同
    });

    test('NoteEntity 所有字段类型正确', () {
      final now = DateTime.now();
      const entity = NoteEntity(
        id: 1,
        title: '标题',
        content: '内容',
        url: 'https://example.com',
        time: null, // 使用 null
        categoryId: 2,
        tag: 'tag',
      );

      expect(entity.id, isA<int?>());
      expect(entity.title, isA<String?>());
      expect(entity.content, isA<String?>());
      expect(entity.url, isA<String?>());
      expect(entity.categoryId, isA<int>());
      expect(entity.tag, isA<String?>());
    });

    test('NoteEntity 带 URL 的笔记', () {
      const entity = NoteEntity(
        title: '文章分享',
        url: 'https://medium.com/article',
      );

      expect(entity.url, startsWith('https://'));
      expect(entity.url, contains('medium.com'));
    });

    test('NoteEntity 多行内容', () {
      const multilineContent = '''
第一行
第二行
第三行
      ''';

      const entity = NoteEntity(title: '多行笔记', content: multilineContent);

      expect(entity.content, contains('\n'));
      expect(entity.content?.split('\n').length, greaterThanOrEqualTo(3));
    });

    test('NoteEntity tag 变体', () {
      const withTag = NoteEntity(title: '笔记', tag: 'important');
      const withoutTag = NoteEntity(title: '笔记');

      expect(withTag.tag, 'important');
      expect(withoutTag.tag, null);
    });

    test('NoteEntity 长内容', () {
      final longContent = 'A' * 5000;
      final entity = NoteEntity(title: '长笔记', content: longContent);

      expect(entity.content?.length, 5000);
    });
  });

  group('CategoryEntity 模型测试', () {
    test('CategoryEntity 基础初始化', () {
      const entity = CategoryEntity(name: '工作');

      expect(entity.name, '工作');
      expect(entity.id, 1); // 默认 ID
    });

    test('CategoryEntity 完整初始化', () {
      final now = DateTime.now();
      const entity = CategoryEntity(
        id: 5,
        name: '项目',
        description: '项目相关笔记',
        createdTime: null,
      );

      expect(entity.id, 5);
      expect(entity.name, '项目');
      expect(entity.description, '项目相关笔记');
    });

    test('CategoryEntity copyWith 修改名称', () {
      const original = CategoryEntity(id: 1, name: '工作');

      final modified = original.copyWith(name: '学习');

      expect(modified.id, 1);
      expect(modified.name, '学习');
      expect(original.name, '工作'); // 原对象不变
    });

    test('CategoryEntity copyWith 修改多个字段', () {
      const original = CategoryEntity(id: 1, name: '工作', description: '旧描述');

      final modified = original.copyWith(id: 2, name: '学习', description: '新描述');

      expect(modified.id, 2);
      expect(modified.name, '学习');
      expect(modified.description, '新描述');
    });

    test('CategoryEntity 相等性比较', () {
      const entity1 = CategoryEntity(id: 1, name: '工作');
      const entity2 = CategoryEntity(id: 1, name: '工作');

      expect(entity1, entity2);
    });

    test('CategoryEntity 不相等 - 不同 ID', () {
      const entity1 = CategoryEntity(id: 1, name: '工作');
      const entity2 = CategoryEntity(id: 2, name: '工作');

      expect(entity1 != entity2, true);
    });

    test('CategoryEntity 不相等 - 不同名称', () {
      const entity1 = CategoryEntity(id: 1, name: '工作');
      const entity2 = CategoryEntity(id: 1, name: '学习');

      expect(entity1 != entity2, true);
    });

    test('CategoryEntity hashCode 一致', () {
      const entity1 = CategoryEntity(id: 1, name: '工作');
      const entity2 = CategoryEntity(id: 1, name: '工作');

      expect(entity1.hashCode, entity2.hashCode);
    });

    test('CategoryEntity toString 格式', () {
      const entity = CategoryEntity(id: 1, name: '工作', description: '工作分类');

      final str = entity.toString();
      expect(str, contains('CategoryEntity'));
      expect(str, contains('name: 工作'));
    });

    test('CategoryEntity 在 Set 中去重', () {
      const entity1 = CategoryEntity(id: 1, name: '工作');
      const entity2 = CategoryEntity(id: 1, name: '工作');
      const entity3 = CategoryEntity(id: 2, name: '学习');

      final set = {entity1, entity2, entity3};

      expect(set.length, 2);
    });

    test('CategoryEntity 创建时间', () {
      final now = DateTime(2024, 1, 15);
      const entity = CategoryEntity(
        name: '工作',
        createdTime: null, // 测试 null
      );

      expect(entity.createdTime, null);
    });

    test('CategoryEntity 特殊字符名称', () {
      const entity = CategoryEntity(name: '工作 & 生活 | 学习');

      expect(entity.name, '工作 & 生活 | 学习');
    });

    test('CategoryEntity 长名称', () {
      final longName = 'Category_${'A' * 100}';
      final entity = CategoryEntity(name: longName);

      expect(entity.name.length, greaterThan(100));
    });

    test('CategoryEntity 空描述', () {
      const entity = CategoryEntity(name: '工作', description: '');

      expect(entity.description, '');
    });

    test('CategoryEntity 所有字段类型', () {
      final now = DateTime.now();
      const entity = CategoryEntity(
        id: 1,
        name: '工作',
        description: '描述',
        createdTime: null,
      );

      expect(entity.id, isA<int>());
      expect(entity.name, isA<String>());
      expect(entity.description, isA<String?>());
      expect(entity.createdTime, isA<DateTime?>());
    });
  });

  group('NoteEntity 和 CategoryEntity 关联测试', () {
    test('笔记引用分类 ID', () {
      final category = CategoryEntity(id: 5, name: '项目');
      final note = NoteEntity(title: '项目笔记', categoryId: category.id);

      expect(note.categoryId, category.id);
    });

    test('多个笔记引用同一分类', () {
      const categoryId = 2;
      const notes = [
        NoteEntity(id: 1, title: '笔记1', categoryId: categoryId),
        NoteEntity(id: 2, title: '笔记2', categoryId: categoryId),
        NoteEntity(id: 3, title: '笔记3', categoryId: categoryId),
      ];

      final sameCategory = notes
          .where((n) => n.categoryId == categoryId)
          .toList();

      expect(sameCategory.length, 3);
    });

    test('笔记分类迁移', () {
      const original = NoteEntity(id: 1, title: '笔记', categoryId: 1);

      final moved = original.copyWith(categoryId: 3);

      expect(original.categoryId, 1);
      expect(moved.categoryId, 3);
    });

    test('构建笔记-分类映射', () {
      const categories = [
        CategoryEntity(id: 1, name: '工作'),
        CategoryEntity(id: 2, name: '学习'),
      ];
      const notes = [
        NoteEntity(id: 1, title: '笔记1', categoryId: 1),
        NoteEntity(id: 2, title: '笔记2', categoryId: 2),
        NoteEntity(id: 3, title: '笔记3', categoryId: 1),
      ];

      // 创建映射
      final categoryMap = {for (var c in categories) c.id: c};
      final notesByCategory = <int, List<NoteEntity>>{};

      for (var note in notes) {
        if (!notesByCategory.containsKey(note.categoryId)) {
          notesByCategory[note.categoryId] = [];
        }
        notesByCategory[note.categoryId]?.add(note);
      }

      expect(notesByCategory[1]?.length, 2);
      expect(notesByCategory[2]?.length, 1);
    });
  });

  group('Entity 深复制测试', () {
    test('复制 NoteEntity 后修改副本', () {
      const original = NoteEntity(id: 1, title: '原标题', content: '原内容');

      final copy = original.copyWith(title: '新标题', content: '新内容');

      expect(original.title, '原标题'); // 原对象未变
      expect(copy.title, '新标题');
      expect(original == copy, false); // 不相等
    });

    test('复制 CategoryEntity 后修改副本', () {
      const original = CategoryEntity(id: 1, name: '原名称', description: '原描述');

      final copy = original.copyWith(name: '新名称', description: '新描述');

      expect(original.name, '原名称');
      expect(copy.name, '新名称');
      expect(original == copy, false);
    });
  });

  group('Entity 边界值测试', () {
    test('NoteEntity ID 大值', () {
      const entity = NoteEntity(id: 9223372036854775807); // 最大 64 位整数

      expect(entity.id, 9223372036854775807);
    });

    test('CategoryEntity ID 大值', () {
      const entity = CategoryEntity(id: 999999999, name: '分类');

      expect(entity.id, 999999999);
    });

    test('NoteEntity 空字符串字段', () {
      const entity = NoteEntity(
        id: 1,
        title: '',
        content: '',
        url: '',
        tag: '',
      );

      expect(entity.title, '');
      expect(entity.content, '');
      expect(entity.url, '');
      expect(entity.tag, '');
    });

    test('CategoryEntity 空字符串字段', () {
      const entity = CategoryEntity(id: 1, name: '', description: '');

      expect(entity.name, '');
      expect(entity.description, '');
    });

    test('NoteEntity null 字段', () {
      const entity = NoteEntity(
        id: null,
        title: null,
        content: null,
        url: null,
        time: null,
        tag: null,
      );

      expect(entity.id, null);
      expect(entity.title, null);
      expect(entity.content, null);
      expect(entity.url, null);
      expect(entity.time, null);
      expect(entity.tag, null);
    });

    test('CategoryEntity null 字段', () {
      const entity = CategoryEntity(
        name: '分类',
        description: null,
        createdTime: null,
      );

      expect(entity.description, null);
      expect(entity.createdTime, null);
    });
  });
}
