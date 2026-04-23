import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/theme';
import { Platform } from 'react-native';

type IoniconsName = React.ComponentProps<typeof Ionicons>['name'];

function TabIcon({
  name,
  focused,
}: {
  name: IoniconsName;
  focused: boolean;
}) {
  return (
    <Ionicons
      name={focused ? name : (`${name}-outline` as IoniconsName)}
      size={24}
      color={focused ? Colors.gold : Colors.textMuted}
    />
  );
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarStyle: {
          backgroundColor: Colors.surface,
          borderTopColor: Colors.cardBorder,
          borderTopWidth: 1,
          height: Platform.OS === 'ios' ? 84 : 64,
          paddingBottom: Platform.OS === 'ios' ? 28 : 10,
          paddingTop: 8,
        },
        tabBarActiveTintColor: Colors.gold,
        tabBarInactiveTintColor: Colors.textMuted,
        tabBarLabelStyle: {
          fontSize: 10,
          fontWeight: '600',
          letterSpacing: 0.3,
        },
        headerStyle: { backgroundColor: Colors.surface },
        headerTintColor: Colors.gold,
        headerTitleStyle: {
          color: Colors.textPrimary,
          fontWeight: '800',
          fontSize: 20,
          letterSpacing: -0.5,
        },
        headerShadowVisible: false,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarLabel: 'Home',
          tabBarIcon: ({ focused }) => <TabIcon name="home" focused={focused} />,
          headerTitle: 'Tempo',
          headerTitleStyle: {
            color: Colors.gold,
            fontWeight: '900',
            fontSize: 26,
            letterSpacing: -1,
          },
        }}
      />
      <Tabs.Screen
        name="scan"
        options={{
          title: 'Scan',
          tabBarLabel: 'Scan',
          tabBarIcon: ({ focused }) => <TabIcon name="camera" focused={focused} />,
          headerTitle: 'Scan Scoresheet',
        }}
      />
      <Tabs.Screen
        name="games"
        options={{
          title: 'Games',
          tabBarLabel: 'Games',
          tabBarIcon: ({ focused }) => <TabIcon name="library" focused={focused} />,
          headerTitle: 'My Games',
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarLabel: 'Profile',
          tabBarIcon: ({ focused }) => <TabIcon name="person" focused={focused} />,
          headerTitle: 'Profile',
        }}
      />
    </Tabs>
  );
}
