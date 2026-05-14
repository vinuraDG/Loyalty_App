import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../services/mock_points_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
        Navigator.pushReplacementNamed(context, AppRoutes.login));
      return const Scaffold();
    }
    final txs = MockPointsService().getTransactions(user.id);
    final offers = MockPointsService().getOffers();
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${user.name.split(' ').first}!',
          style:AppTextStyles.heading2),
        actions:[
          IconButton(icon:const Icon(Icons.logout_rounded),
            onPressed:(){
              auth.logout();
              Navigator.pushReplacementNamed(context,AppRoutes.login);
            }),
        ],
      ),
      body: ListView(padding:const EdgeInsets.all(20),children:[
        // Points card
        Container(
          padding:const EdgeInsets.all(22),
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[AppColors.primary,
              Color(0xFF9B59B6)],begin:Alignment.topLeft,end:Alignment.bottomRight),
            borderRadius:BorderRadius.circular(20)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.tier.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              PointsBadge(points:user.points),
            ]),
            const SizedBox(height:16),
            Text('${user.points}',style:const TextStyle(
              fontFamily:'Poppins',fontSize:44,fontWeight:FontWeight.w700,
              color:Colors.white)),
            const Text('Total points',style:TextStyle(
              fontFamily:'Poppins',fontSize:13,color:Colors.white70)),
            if(user.pointsToNextTier > 0) ...[
              const SizedBox(height:12),
              Text('${user.pointsToNextTier} pts to next tier',
                style:const TextStyle(fontFamily:'Poppins',
                  fontSize:12,color:Colors.white70)),
            ],
          ]),
        ),
        const SizedBox(height:24),
        // Offers
        const Text('Offers for you', style:AppTextStyles.heading2),
        const SizedBox(height:12),
        SizedBox(height:130, child:ListView.separated(
          scrollDirection:Axis.horizontal,
          itemCount:offers.length,
          separatorBuilder:(_,__)=>const SizedBox(width:12),
          itemBuilder:(ctx,i){
            final o = offers[i];
            return Container(width:170,
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                color:AppColors.surface,
                borderRadius:BorderRadius.circular(14),
                border:Border.all(color:const Color(0xFFE8E8E8))),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                if(o.isFeatured) Container(
                  padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
                  decoration:BoxDecoration(
                    color:AppColors.primary.withOpacity(0.1),
                    borderRadius:BorderRadius.circular(6)),
                  child:const Text('Featured',style:TextStyle(
                    fontFamily:'Poppins',fontSize:10,color:AppColors.primary,
                    fontWeight:FontWeight.w600))),
                const SizedBox(height:6),
                Text(o.title,style:AppTextStyles.body.copyWith(
                  fontWeight:FontWeight.w600)),
                const Spacer(),
                Text('${o.pointsCost} pts',style:TextStyle(
                  fontFamily:'Poppins',fontSize:13,fontWeight:FontWeight.w700,
                  color:AppColors.primary)),
              ]),
            );
          },
        )),
        const SizedBox(height:24),
        // Transactions
        const Text('Recent activity', style:AppTextStyles.heading2),
        const SizedBox(height:4),
        ...txs.take(5).map((t)=>TransactionTile(tx:t)),
      ]),
    );
  }
}