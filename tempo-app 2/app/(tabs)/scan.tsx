import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
  Animated,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { Image } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors, Spacing, Radius, Typography } from '../../constants/theme';
import { scanScoresheet } from '../../services/ocr';
import { OCRResult } from '../../constants/types';

type ScanState = 'idle' | 'scanning' | 'done' | 'error';

const SCAN_STEPS = [
  'Detecting scoresheet edges…',
  'Running OCR on moves…',
  'Parsing chess notation…',
  'Flagging uncertain moves…',
];

export default function ScanScreen() {
  const [imageUri, setImageUri] = useState<string | null>(null);
  const [scanState, setScanState] = useState<ScanState>('idle');
  const [stepIndex, setStepIndex] = useState(0);
  const [ocrResult, setOcrResult] = useState<OCRResult | null>(null);

  const pickImage = async (fromCamera: boolean) => {
    let result;
    if (fromCamera) {
      const { status } = await ImagePicker.requestCameraPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission needed', 'Camera access is required to scan scoresheets.');
        return;
      }
      result = await ImagePicker.launchCameraAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        quality: 0.9,
        allowsEditing: true,
        aspect: [3, 4],
      });
    } else {
      result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        quality: 0.9,
        allowsEditing: true,
        aspect: [3, 4],
      });
    }

    if (!result.canceled && result.assets[0]) {
      setImageUri(result.assets[0].uri);
      startScan(result.assets[0].uri);
    }
  };

  const startScan = async (uri: string) => {
    setScanState('scanning');
    setStepIndex(0);

    // Step ticker
    const interval = setInterval(() => {
      setStepIndex((prev) => Math.min(prev + 1, SCAN_STEPS.length - 1));
    }, 650);

    try {
      const result = await scanScoresheet(uri);
      clearInterval(interval);
      setOcrResult(result);
      setScanState('done');
    } catch (err) {
      clearInterval(interval);
      setScanState('error');
    }
  };

  const proceedToConfirm = async () => {
    if (!ocrResult) return;
    await AsyncStorage.setItem('tempo:pendingOcr', JSON.stringify(ocrResult));
    router.push('/confirm');
  };

  const reset = () => {
    setImageUri(null);
    setScanState('idle');
    setOcrResult(null);
    setStepIndex(0);
  };

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      {/* Image preview area */}
      <View style={styles.previewArea}>
        {imageUri ? (
          <Image source={{ uri: imageUri }} style={styles.previewImage} resizeMode="cover" />
        ) : (
          <LinearGradient
            colors={[Colors.card, Colors.surface]}
            style={styles.previewPlaceholder}
          >
            <View style={styles.scanFrame}>
              <View style={[styles.corner, styles.cornerTL]} />
              <View style={[styles.corner, styles.cornerTR]} />
              <View style={[styles.corner, styles.cornerBL]} />
              <View style={[styles.corner, styles.cornerBR]} />
            </View>
            <Ionicons name="document-text-outline" size={48} color={Colors.textMuted} />
            <Text style={styles.placeholderText}>Scoresheet will appear here</Text>
          </LinearGradient>
        )}
      </View>

      {/* Scan status */}
      {scanState === 'scanning' && (
        <View style={styles.statusCard}>
          <ActivityIndicator color={Colors.gold} size="small" />
          <Text style={styles.statusText}>{SCAN_STEPS[stepIndex]}</Text>
        </View>
      )}

      {scanState === 'done' && ocrResult && (
        <View style={styles.successCard}>
          <Ionicons name="checkmark-circle" size={24} color={Colors.good} />
          <View style={styles.successBody}>
            <Text style={styles.successTitle}>Scan complete!</Text>
            <Text style={styles.successSub}>
              {ocrResult.uncertainMoves.length > 0
                ? `${ocrResult.uncertainMoves.length} uncertain move${ocrResult.uncertainMoves.length > 1 ? 's' : ''} need your review`
                : 'All moves detected with high confidence'}
            </Text>
          </View>
        </View>
      )}

      {scanState === 'error' && (
        <View style={styles.errorCard}>
          <Ionicons name="alert-circle" size={24} color={Colors.blunder} />
          <Text style={styles.errorText}>Scan failed. Please try again.</Text>
        </View>
      )}

      {/* Action buttons */}
      <View style={styles.actions}>
        {(scanState === 'idle' || scanState === 'error') && (
          <>
            <TouchableOpacity
              style={styles.primaryBtn}
              onPress={() => pickImage(true)}
              activeOpacity={0.85}
            >
              <LinearGradient
                colors={[Colors.goldBright, Colors.gold]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                style={styles.primaryBtnGradient}
              >
                <Ionicons name="camera" size={20} color={Colors.bg} />
                <Text style={styles.primaryBtnText}>Take Photo</Text>
              </LinearGradient>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.secondaryBtn}
              onPress={() => pickImage(false)}
              activeOpacity={0.85}
            >
              <Ionicons name="image-outline" size={20} color={Colors.gold} />
              <Text style={styles.secondaryBtnText}>Choose from Gallery</Text>
            </TouchableOpacity>
          </>
        )}

        {scanState === 'done' && (
          <>
            <TouchableOpacity
              style={styles.primaryBtn}
              onPress={proceedToConfirm}
              activeOpacity={0.85}
            >
              <LinearGradient
                colors={[Colors.goldBright, Colors.gold]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                style={styles.primaryBtnGradient}
              >
                <Ionicons name="arrow-forward" size={20} color={Colors.bg} />
                <Text style={styles.primaryBtnText}>Review Moves</Text>
              </LinearGradient>
            </TouchableOpacity>

            <TouchableOpacity style={styles.secondaryBtn} onPress={reset} activeOpacity={0.85}>
              <Ionicons name="refresh-outline" size={20} color={Colors.gold} />
              <Text style={styles.secondaryBtnText}>Scan Again</Text>
            </TouchableOpacity>
          </>
        )}
      </View>

      {/* Scanning step tracker */}
      {scanState === 'scanning' && (
        <View style={styles.stepTracker}>
          {SCAN_STEPS.map((step, i) => (
            <View key={i} style={styles.stepRow}>
              <View
                style={[
                  styles.stepDot,
                  i < stepIndex && styles.stepDotDone,
                  i === stepIndex && styles.stepDotActive,
                ]}
              />
              <Text
                style={[
                  styles.stepLabel,
                  i <= stepIndex && styles.stepLabelActive,
                ]}
              >
                {step}
              </Text>
            </View>
          ))}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md, paddingBottom: 40, gap: Spacing.md },

  previewArea: {
    borderRadius: Radius.lg,
    overflow: 'hidden',
    height: 320,
  },
  previewImage: {
    width: '100%',
    height: '100%',
    borderRadius: Radius.lg,
  },
  previewPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 12,
    borderRadius: Radius.lg,
    borderWidth: 2,
    borderColor: Colors.cardBorder,
    borderStyle: 'dashed',
  },
  placeholderText: {
    ...Typography.caption,
    color: Colors.textMuted,
  },
  scanFrame: {
    position: 'absolute',
    top: 20,
    left: 20,
    right: 20,
    bottom: 20,
  },
  corner: {
    position: 'absolute',
    width: 24,
    height: 24,
    borderColor: Colors.gold,
    borderWidth: 2,
  },
  cornerTL: { top: 0, left: 0, borderRightWidth: 0, borderBottomWidth: 0, borderRadius: 3 },
  cornerTR: { top: 0, right: 0, borderLeftWidth: 0, borderBottomWidth: 0, borderRadius: 3 },
  cornerBL: { bottom: 0, left: 0, borderRightWidth: 0, borderTopWidth: 0, borderRadius: 3 },
  cornerBR: { bottom: 0, right: 0, borderLeftWidth: 0, borderTopWidth: 0, borderRadius: 3 },

  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.cardBorder,
  },
  statusText: {
    ...Typography.body,
    color: Colors.textSecondary,
  },

  successCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    backgroundColor: Colors.good + '15',
    borderRadius: Radius.md,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.good + '44',
  },
  successBody: { flex: 1 },
  successTitle: { ...Typography.subtitle, fontSize: 15, color: Colors.good },
  successSub: { ...Typography.caption, color: Colors.textSecondary, marginTop: 2 },

  errorCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    backgroundColor: Colors.blunder + '15',
    borderRadius: Radius.md,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.blunder + '44',
  },
  errorText: { ...Typography.body, color: Colors.blunder },

  actions: { gap: Spacing.sm },
  primaryBtn: { borderRadius: Radius.round, overflow: 'hidden' },
  primaryBtnGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 15,
    gap: 8,
  },
  primaryBtnText: { ...Typography.subtitle, color: Colors.bg, fontWeight: '800' },
  secondaryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.card,
    borderRadius: Radius.round,
    paddingVertical: 14,
    gap: 8,
    borderWidth: 1,
    borderColor: Colors.gold + '55',
  },
  secondaryBtnText: { ...Typography.subtitle, fontSize: 15, color: Colors.gold },

  stepTracker: {
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    padding: Spacing.md,
    gap: Spacing.sm,
    borderWidth: 1,
    borderColor: Colors.cardBorder,
  },
  stepRow: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  stepDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: Colors.textMuted,
  },
  stepDotActive: { backgroundColor: Colors.gold },
  stepDotDone: { backgroundColor: Colors.good },
  stepLabel: { ...Typography.caption, color: Colors.textMuted },
  stepLabelActive: { color: Colors.textSecondary },
});
