const List<String> expenseCategories = [
  'An uong',
  'Di chuyen',
  'Nha o',
  'Mua sam',
  'Hoc tap',
  'Khac',
];

const List<String> incomeCategories = [
  'Luong',
  'Thuong',
  'Dau tu',
  'Ban hang',
  'Khac',
];

const Map<String, String> _categoryDisplayMap = {
  'An uong': 'Ăn uống',
  'Di chuyen': 'Di chuyển',
  'Nha o': 'Nhà ở',
  'Mua sam': 'Mua sắm',
  'Hoc tap': 'Học tập',
  'Khac': 'Khác',
  'Luong': 'Lương',
  'Thuong': 'Thưởng',
  'Dau tu': 'Đầu tư',
  'Ban hang': 'Bán hàng',
  'Ăn uống': 'Ăn uống',
  'Di chuyển': 'Di chuyển',
  'Nhà ở': 'Nhà ở',
  'Mua sắm': 'Mua sắm',
  'Học tập': 'Học tập',
  'Khác': 'Khác',
  'Lương': 'Lương',
  'Thưởng': 'Thưởng',
  'Đầu tư': 'Đầu tư',
  'Bán hàng': 'Bán hàng',
};

String categoryDisplayName(String category) {
  return _categoryDisplayMap[category] ?? category;
}
