import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { Colors, Typography } from '../constants/theme';
import { evalLabel, evalToBarRatio } from '../services/chess';

interface Props {
  cp?: number;
  mate?: number;
  height?: number;
}

export default function EvalBar({ cp, mate, height = 18 }: Props) {
  const animated = useRef(new Animated.Value(0.5)).current;

  const ratio = evalToBarRatio(cp, mate);

  useEffect(() => {
    Animated.spring(animated, {
      toValue: ratio,
      tension: 50,
      friction: 10,
      useNativeDriver: false,
    }).start();
  }, [ratio]);

  const label = evalLabel(cp, mate);
  const whiteAhead = (cp ?? 0) >= 0 && mate !== undefined ? mate > 0 : (cp ?? 0) >= 0;

  return (
    <View style={[styles.container, { height }]}>
      {/* Black portion */}
      <Animated.View
        style={[
          styles.blackPortion,
          {
            flex: animated.interpolate({
              inputRange: [0, 1],
              outputRange: [1, 0],
            }),
          },
        ]}
      />
      {/* White portion */}
      <Animated.View
        style={[
          styles.whitePortion,
          {
            flex: animated,
          },
        ]}
      />
      {/* Eval label */}
      <View style={[styles.labelContainer, whiteAhead ? styles.labelRight : styles.labelLeft]}>
        <Text style={[styles.label, { color: whiteAhead ? Colors.evalBlack : Colors.evalWhite }]}>
          {label}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    borderRadius: 4,
    overflow: 'hidden',
    position: 'relative',
    borderWidth: 1,
    borderColor: Colors.cardBorder,
  },
  blackPortion: {
    backgroundColor: '#1A1A24',
  },
  whitePortion: {
    backgroundColor: '#F0EDE8',
  },
  labelContainer: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    justifyContent: 'center',
    paddingHorizontal: 6,
  },
  labelLeft: { left: 0 },
  labelRight: { right: 0 },
  label: {
    ...Typography.tiny,
    fontWeight: '700',
  },
});
