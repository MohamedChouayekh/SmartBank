import 'package:flutter/material.dart';

class CardsScreen extends StatelessWidget {
  final String firstName;

  const CardsScreen({
    super.key,
    required this.firstName,
  });

  static const Color blue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  static const Color yellow =
      Color(0xFFF4C542);

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final fullName =
        firstName.trim().isEmpty
            ? 'SMARTBANK CLIENT'
            : firstName.toUpperCase();

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF0F1723)
              : const Color(0xFFF5F7FA),

      appBar:
          AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title:
            const Text(
          'Mes cartes',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body:
          SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            30,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Vos cartes bancaires',
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Gérez vos moyens de paiement SmartBank.',
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(
                    alpha:
                        0.68,
                  ),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              _buildBankCard(
                context: context,
                cardType:
                    'Visa Classic',
                number:
                    '••••  ••••  ••••  4582',
                holder:
                    fullName,
                expiry:
                    '09/28',
                color1:
                    blue,
                color2:
                    darkBlue,
                logo:
                    'VISA',
                chipColor:
                    yellow,
              ),

              const SizedBox(
                height: 18,
              ),

              _buildBankCard(
                context: context,
                cardType:
                    'Mastercard Gold',
                number:
                    '••••  ••••  ••••  7821',
                holder:
                    fullName,
                expiry:
                    '12/27',
                color1:
                    const Color(
                  0xFF202735,
                ),
                color2:
                    const Color(
                  0xFF111722,
                ),
                logo:
                    '●●',
                chipColor:
                    yellow,
              ),

              const SizedBox(
                height: 26,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      isDark
                          ? const Color(
                              0xFF182236,
                            )
                          : Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border:
                      Border.all(
                    color:
                        blue.withValues(
                      alpha:
                          0.10,
                    ),
                  ),
                ),
                child:
                    Row(
                  children: [
                    Container(
                      width:
                          44,
                      height:
                          44,
                      decoration:
                          BoxDecoration(
                        color:
                            yellow.withValues(
                          alpha:
                              0.18,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .security_rounded,
                        color:
                            darkBlue,
                      ),
                    ),
                    const SizedBox(
                      width:
                          12,
                    ),
                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Paiements sécurisés',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height:
                                4,
                          ),
                          Text(
                            'Vos informations de carte restent protégées.',
                            style:
                                TextStyle(
                              color:
                                  theme.textTheme.bodyMedium?.color?.withValues(
                                alpha:
                                    0.68,
                              ),
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              SizedBox(
                width:
                    double.infinity,
                height:
                    54,
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content:
                            Text(
                          'Fonctionnalité bientôt disponible.',
                        ),
                      ),
                    );
                  },
                  icon:
                      const Icon(
                    Icons.add_card_rounded,
                  ),
                  label:
                      const Text(
                    'Ajouter une carte',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    side:
                        BorderSide(
                      color:
                          blue.withValues(
                        alpha:
                            0.35,
                      ),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankCard({
    required BuildContext context,
    required String cardType,
    required String number,
    required String holder,
    required String expiry,
    required Color color1,
    required Color color2,
    required String logo,
    required Color chipColor,
  }) {
    return Container(
      width:
          double.infinity,
      height:
          215,
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            color1,
            color2,
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color:
                color1.withValues(
              alpha:
                  0.30,
            ),
            blurRadius:
                22,
            offset:
                const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child:
          Stack(
        children: [
          Positioned(
            right:
                -35,
            top:
                -40,
            child:
                Container(
              width:
                  160,
              height:
                  160,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white.withValues(
                  alpha:
                      0.06,
                ),
              ),
            ),
          ),

          Positioned(
            left:
                -40,
            bottom:
                -65,
            child:
                Container(
              width:
                  150,
              height:
                  150,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white.withValues(
                  alpha:
                      0.04,
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardType,
                      style:
                          TextStyle(
                        color:
                            Colors.white.withValues(
                          alpha:
                              0.80,
                        ),
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    Text(
                      logo,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            1.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      12,
                ),

                Container(
                  width:
                      45,
                  height:
                      32,
                  decoration:
                      BoxDecoration(
                    color:
                        chipColor,
                    borderRadius:
                        BorderRadius.circular(
                      7,
                    ),
                  ),
                  child:
                      Stack(
                    children: [
                      Positioned(
                        left:
                            14,
                        top:
                            0,
                        bottom:
                            0,
                        child:
                            Container(
                          width:
                              1,
                          color:
                              color1.withValues(
                            alpha:
                                0.28,
                          ),
                        ),
                      ),
                      Positioned(
                        top:
                            15,
                        left:
                            0,
                        right:
                            0,
                        child:
                            Container(
                          height:
                              1,
                          color:
                              color1.withValues(
                            alpha:
                                0.28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Text(
                  number,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.w500,
                    letterSpacing:
                        2,
                  ),
                ),

                const SizedBox(
                  height:
                      17,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TITULAIRE',
                            style:
                                TextStyle(
                              color:
                                  Colors.white.withValues(
                                alpha:
                                    0.52,
                              ),
                              fontSize:
                                  9,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height:
                                3,
                          ),
                          Text(
                            holder,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRE',
                          style:
                              TextStyle(
                            color:
                                Colors.white.withValues(
                              alpha:
                                  0.52,
                            ),
                            fontSize:
                                9,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height:
                              3,
                        ),
                        Text(
                          expiry,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}