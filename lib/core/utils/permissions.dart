/// Permission codes enforced by the backend's `@PreAuthorize` checks.
/// Mirrors frontend/src/constants/Permission.ts (only codes the mobile app uses).
class Perm {
  Perm._();

  static const saleRead = 'sale:read';
  static const saleCreate = 'sale:create';
  static const saleUpdate = 'sale:update';
  static const saleDelete = 'sale:delete';

  static const paymentRead = 'payment:read';
  static const paymentCreate = 'payment:create';
  static const paymentDelete = 'payment:delete';

  static const customerRead = 'customer:read';
  static const customerCreate = 'customer:create';
  static const customerUpdate = 'customer:update';
  static const customerDelete = 'customer:delete';

  static const quoteRead = 'quote:read';
  static const quoteCreate = 'quote:create';
  static const quoteDelete = 'quote:delete';

  static const productRead = 'product:read';
  static const productCreate = 'product:create';
  static const productUpdate = 'product:update';
  static const productDelete = 'product:delete';
  static const categoryRead = 'category:read';
  static const brandRead = 'brand:read';
  static const modelRead = 'model:read';

  static const stockRead = 'stock:read';
  static const storeRead = 'store:read';
  static const storeCreate = 'store:create';
  static const storeUpdate = 'store:update';
  static const storeDelete = 'store:delete';

  static const purchaseRead = 'purchase:read';
  static const purchaseCreate = 'purchase:create';
  static const purchaseDelete = 'purchase:delete';
  static const supplierRead = 'supplier:read';
  static const supplierCreate = 'supplier:create';
  static const supplierUpdate = 'supplier:update';
  static const supplierDelete = 'supplier:delete';

  static const expenseRead = 'expense:read';
  static const expenseCreate = 'expense:create';
  static const expenseUpdate = 'expense:update';
  static const expenseDelete = 'expense:delete';
  static const expenseTypeRead = 'expensesType:read';

  static const bankRead = 'bank:read';
  static const bankCreate = 'bank:create';
  static const bankUpdate = 'bank:update';
  static const bankDelete = 'bank:delete';
  static const currencyRead = 'currency:read';
  static const currencyCreate = 'currency:create';
  static const currencyUpdate = 'currency:update';
  static const currencyDelete = 'currency:delete';

  static const reportRead = 'report:read';

  static const userRead = 'user:read';
  static const userUpdate = 'user:update';
  static const roleRead = 'role:read';

  static const fileUpload = 'file:upload';
  static const fileRead = 'file:read';
}
