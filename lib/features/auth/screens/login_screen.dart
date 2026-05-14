import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass  = TextEditingController();
  String? _err;

  Future<void> _login() async {
    setState(() => _err = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_phone.text.trim(), _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() => _err = auth.error);
    }
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(child:Padding(padding:const EdgeInsets.all(24),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const SizedBox(height:40),
          const Text('Welcome back', style:AppTextStyles.heading1),
          const SizedBox(height:6),
          const Text('Sign in to your account',
            style:AppTextStyles.caption),
          const SizedBox(height:36),
          AppTextField(hint:'Phone number', controller:_phone,
            keyboardType:TextInputType.phone),
          const SizedBox(height:14),
          AppTextField(hint:'Password', controller:_pass, obscure:true),
          if (_err != null) ...[
            const SizedBox(height:8),
            Text(_err!, style:const TextStyle(color:Colors.red,fontSize:12)),
          ],
          const SizedBox(height:24),
          AppButton(label:'Sign In', onTap:_login,
            isLoading:auth.isLoading),
          const SizedBox(height:16),
          Center(child:GestureDetector(
            onTap:()=>Navigator.pushNamed(context,AppRoutes.signup),
            child:const Text.rich(TextSpan(children:[
              TextSpan(text:"Don't have an account? ",
                style:AppTextStyles.caption),
              TextSpan(text:'Sign Up',
                style:TextStyle(color:AppColors.primary,
                  fontWeight:FontWeight.w600,fontSize:12)),
            ])),
          )),
        ]),
      )),
    );
  }
}