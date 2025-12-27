import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/utils/error_mapper.dart';

class CardState extends Equatable {
  final List<CreditCard> cards;
  final bool loading;
  final String? error;

  const CardState({this.cards = const [], this.loading = false, this.error});

  CardState copyWith({List<CreditCard>? cards, bool? loading, String? error}) {
    return CardState(
      cards: cards ?? this.cards,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [cards, loading, error];
}

class CardCubit extends Cubit<CardState> {
  CardCubit(this._repository, {NotificationService? notificationService})
    : _notifications = notificationService ?? NotificationService.instance,
      super(const CardState());

  final CardRepository _repository;
  final NotificationService _notifications;

  Future<void> loadCards() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final cards = await _repository.fetchCards();
      emit(state.copyWith(cards: cards, loading: false));
      await _notifications.scheduleCardReminders(cards);
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Load cards failed');
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Load cards'),
        ),
      );
    }
  }

  Future<void> addCard(CreditCard card) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveCard(card);
      final updated = [card, ...state.cards.where((c) => c.id != card.id)];
      emit(state.copyWith(cards: updated, loading: false));
      await _notifications.scheduleCardReminders(updated);
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Save card failed');
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Save card'),
        ),
      );
    }
  }

  Future<void> deleteCard(String id) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteCard(id);
      final updated = state.cards.where((c) => c.id != id).toList();
      emit(state.copyWith(cards: updated, loading: false));
      await _notifications.scheduleCardReminders(updated);
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Delete card failed');
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Delete card'),
        ),
      );
    }
  }
}
