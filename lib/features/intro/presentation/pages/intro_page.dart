import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/di/injection_container.dart';
import 'package:flutter_steps_tracker/features/intro/presentation/manager/auth_actions/auth_cubit.dart';
import 'package:flutter_steps_tracker/features/intro/presentation/manager/auth_actions/auth_state.dart';
import 'package:flutter_steps_tracker/features/intro/presentation/manager/auth_status/auth_status_cubit.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';
import 'package:flutter_steps_tracker/utilities/constants/assets.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        backgroundColor: const Color(0xFF000612),
        // 让我们自己控制键盘
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 背景图（名字不变）
            Image.asset(
              AppAssets.manInBackgroundIntro,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // 深色渐变罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF020B16).withValues(alpha: .85),
                    const Color(0xFF031629).withValues(alpha: .88),
                    const Color(0xFF000612).withValues(alpha: .95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyboard = MediaQuery.of(context).viewInsets.bottom;

                  return SingleChildScrollView(
                    // 键盘弹起时往上推
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      keyboard + 16,
                    ),
                    child: ConstrainedBox(
                      // 没键盘时至少跟屏幕一样高
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: BlocConsumer<AuthCubit, AuthState>(
                        listener: (context, state) {
                          state.maybeWhen(
                            loggedIn: () {
                              context.read<AuthStatusCubit>().checkAuthStatus();
                            },
                            orElse: () {},
                          );
                        },
                        builder: (context, state) {
                          final isLoading = state.maybeWhen(
                            loading: () => true,
                            orElse: () => false,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 顶部品牌条
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: const Color(0x1A00E5FF),
                                    border: Border.all(
                                      color: const Color(0x33D4EEFF),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sports_score_rounded,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'The Game That Make You Move',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 中间玻璃卡（居中 + 限宽）
                              Center(
                                child: SizedBox(
                                  width: 430,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 18, sigmaY: 18),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 20, 20, 20),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(26),
                                          color: const Color(0x1A0B2742),
                                          border: Border.all(
                                            color: const Color(0x33D4EEFF),
                                          ),
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // 右上角 logo（名字不变）
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        16),
                                                    color: const Color(
                                                        0x2600E5FF),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Image.network(
                                                    AppAssets.logo,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                    const Icon(
                                                      Icons
                                                          .directions_walk_rounded,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              const Text(
                                                'Move. Earn. Grow.',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Your all-in one activity tracker!',
                                                style: TextStyle(
                                                  color: Color(0x99D6E7FF),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              // 输入框
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(18),
                                                  color: const Color(
                                                      0x12000000),
                                                  border: Border.all(
                                                    color: const Color(
                                                        0x26FFFFFF),
                                                  ),
                                                ),
                                                child: TextFormField(
                                                  controller: _nameController,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                  validator: (v) =>
                                                  (v == null ||
                                                      v.trim().isEmpty)
                                                      ? S
                                                      .of(context)
                                                      .enterYourName
                                                      : null,
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 14,
                                                    ),
                                                    border: InputBorder.none,
                                                    hintText: S
                                                        .of(context)
                                                        .enterYourName,
                                                    hintStyle: const TextStyle(
                                                      color: Color(0x55FFFFFF),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              // 按钮
                                              SizedBox(
                                                height: 54,
                                                width: double.infinity,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                    const LinearGradient(
                                                      colors: [
                                                        Color(0xFF00E5FF),
                                                        Color(0xFF4A5CFF)
                                                      ],
                                                      begin:
                                                      Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight,
                                                    ),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        18),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color:
                                                        const Color(
                                                            0xFF00E5FF)
                                                            .withValues(
                                                            alpha: .35),
                                                        blurRadius: 16,
                                                        offset:
                                                        const Offset(0, 7),
                                                      ),
                                                    ],
                                                  ),
                                                  child: TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () async {
                                                      if (_formKey
                                                          .currentState!
                                                          .validate()) {
                                                        await context
                                                            .read<
                                                            AuthCubit>()
                                                            .signInAnonymously(
                                                          name: _nameController
                                                              .text
                                                              .trim(),
                                                        );
                                                      }
                                                    },
                                                    style: TextButton.styleFrom(
                                                      shape:
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(18),
                                                      ),
                                                    ),
                                                    child: isLoading
                                                        ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors
                                                                .white),
                                                      ),
                                                    )
                                                        : Text(
                                                      S
                                                          .of(context)
                                                          .startUsingSteps,
                                                      style:
                                                      const TextStyle(
                                                        color:
                                                        Colors.white,
                                                        fontWeight:
                                                        FontWeight
                                                            .w700,
                                                        fontSize: 14.7,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 底部提示
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline,
                                      color: Color(0x55FFFFFF), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Anonymous login · no password',
                                    style: TextStyle(
                                      color: Color(0x55FFFFFF),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
