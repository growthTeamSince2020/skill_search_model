import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class dataUtils {

  /**
   * ログイン中ユーザーの所属企業情報を取得する
   *
   * users コレクションから companyCode を取得し、
   * companies コレクションから companyName を引いた結果を
   * CompanyInfoResult として返す。
   *
   * @param firestore Firestoreのインスタンス
   * @return Future<CompanyInfoResult> 取得結果（エラー時は errorMessage が入る）
   */
  static Future<
      ({dynamic companyCode, String companyName, dynamic displayName, String? errorMessage})>
  fetchMyCompanyInfo(FirebaseFirestore firestore) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return (companyCode: '', companyName: '', displayName: '', errorMessage: "ログイン情報が確認できません。");
      }

      final userDoc = await firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final companyCode = userData?['companyCode'] ?? '';

      if (companyCode.toString().isEmpty) {
        return (companyCode: '', companyName: '', displayName: '', errorMessage: "所属企業（法人コード）が設定されてません。");
      }

      String companyName = '';
      final companyDoc = await firestore.collection('companies').doc(
          companyCode).get();
      if (companyDoc.exists) {
        companyName = companyDoc.data()?['companyName'] ?? '';
      }

      return (companyCode: companyCode, companyName: companyName, displayName: userData?['displayName'] ??
          '', errorMessage: null);
    } catch (e) {
      return (companyCode: '', companyName: '', displayName: '', errorMessage: "情報取得エラー: $e");
    }
  }
}
/**
 * 日付操作
 */
